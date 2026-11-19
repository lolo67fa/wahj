//
//  SharedJourneys.swift
//  Shared
//
//  Habit journeys shared between friends, stored in Cloud Firestore.
//
//  Firestore layout (see firebase/firestore.rules):
//    journeys/{journeyId}                      habit title/icon/days, constellation, creator
//    journeys/{journeyId}/members/{uid}        display name, role, streak, active
//    journeys/{journeyId}/completions/{uid_day} one per member per day (no duplicate points)
//    invites/{code}                            random code, journey summary, expiry, revoked
//    users/{uid}/journeys/{journeyId}          the user's own list of journeys
//
//  Only the shared habit, the members' display names, streaks and completed
//  days go to Firestore. Personal habits, emails and passwords never do.
//

import Foundation
import FirebaseFirestore
import Security
import os

// Step-by-step log for the friends feature: ids, counts and error codes only.
let journeyLog = Logger(subsystem: "com.ghalaalshreef.wahj", category: "journeys")

// Logs a friends-feature step (ids, counts, error codes; never names or emails).
// Debug builds also print it, so it shows in the device console.
func journeyTrace(_ message: String) {
    journeyLog.notice("\(message, privacy: .public)")
    #if DEBUG
    print("[Journeys] \(message)")
    #endif
}

// MARK: - Invite codes

enum InviteCode {
    // Crockford base32: no I, L, O, U, so codes are easy to read and type.
    nonisolated private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    nonisolated static let length = 20                 // 20 × 5 bits = 100 random bits
    static let lifetime: TimeInterval = 7 * 24 * 60 * 60
    // The invite page (Firebase Hosting). It only shows the code and an "open the app" button.
    static let webBase = "https://wahj-ad44b.web.app/i/"

    static func make() -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        precondition(status == errSecSuccess, "No secure random bytes")
        // 256 is a multiple of 32, so `% 32` has no bias.
        return String(bytes.map { alphabet[Int($0) % alphabet.count] })
    }

    // Accepts what people paste or type: lower case, spaces, dashes, O/I/L look-alikes.
    nonisolated static func normalize(_ input: String) -> String? {
        var code = input.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        code = String(code.map { $0 == "O" ? "0" : ($0 == "I" || $0 == "L") ? "1" : $0 })
        guard code.count == length, code.allSatisfy(alphabet.contains) else { return nil }
        return code
    }

    static func formatted(_ code: String) -> String {
        stride(from: 0, to: code.count, by: 5).map { start in
            let from = code.index(code.startIndex, offsetBy: start)
            let to = code.index(from, offsetBy: min(5, code.count - start))
            return String(code[from..<to])
        }.joined(separator: "-")
    }

    static func webLink(for code: String) -> URL { URL(string: webBase + code)! }
    static func appLink(for code: String) -> URL { URL(string: "wahj://invite/\(code)")! }

    // wahj://invite/CODE  or  https://wahj-ad44b.web.app/i/CODE
    static func from(url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        if url.scheme == "wahj", url.host == "invite" {
            return parts.first.flatMap(normalize)
        }
        if url.scheme == "https", url.host == "wahj-ad44b.web.app" || url.host == "wahj-ad44b.firebaseapp.com",
           parts.count == 2, parts[0] == "i" {
            return normalize(parts[1])
        }
        return nil
    }
}

// An invite opened before signing in (or before onboarding) waits here on this
// device; RootView picks it up once the account is ready. It holds only the code.
@Observable
final class InviteInbox {
    private static let key = "pendingInviteCode"
    private(set) var code: String? = UserDefaults.standard.string(forKey: InviteInbox.key)

    func receive(_ code: String) {
        self.code = code
        UserDefaults.standard.set(code, forKey: Self.key)
    }

    func clear() {
        code = nil
        UserDefaults.standard.removeObject(forKey: Self.key)
    }
}

// MARK: - Models

struct SharedJourney: Identifiable, Equatable {
    let id: String
    var habitTitle: String
    var habitIcon: String
    var habitDays: [Int]
    var constellationIndex: Int
    var createdBy: String
    var createdAt: Date?
}

struct JourneyMember: Identifiable, Equatable {
    let id: String          // Firebase UID
    var displayName: String
    var role: String        // "owner" or "member"
    var streak: Int
    var active: Bool
    var joinedAt: Date?
}

struct JourneyCompletion: Equatable {
    let uid: String
    let day: String
}

struct JourneyState: Identifiable, Equatable {
    var journey: SharedJourney
    var members: [JourneyMember]
    var completions: [JourneyCompletion]

    var id: String { journey.id }

    // Built only from this journey's completions; 5 each, complete at 100.
    var points: Int {
        min(completions.count * HabitProgress.pointsPerCompletion, HabitProgress.pointsPerConstellation)
    }

    func contribution(of uid: String) -> Int {
        completions.filter { $0.uid == uid }.count * HabitProgress.pointsPerCompletion
    }
}

struct InviteSummary: Identifiable, Equatable {
    let code: String
    let journeyId: String
    let inviterUid: String
    let inviterName: String
    let habitTitle: String
    let habitIcon: String
    let habitDays: [Int]
    let constellationIndex: Int
    let expiresAt: Date
    let revoked: Bool

    var id: String { code }
    var isExpired: Bool { expiresAt < .now }
}

enum InviteLookup: Equatable {
    case ready(InviteSummary)
    case invalid
    case expired
    case revoked
    case alreadyMember(journeyId: String)
}

enum InviteAcceptResult: Equatable {
    case joined(journeyId: String)
    case alreadyMember(journeyId: String)
    case invalid, expired, revoked
}

enum JourneyError: LocalizedError {
    case notSignedIn
    case invalid, expired, revoked

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "سجّلي دخولك أولًا."
        case .invalid: return "رمز الدعوة غير صحيح."
        case .expired: return "انتهت صلاحية هذه الدعوة."
        case .revoked: return "أُلغيت هذه الدعوة."
        }
    }
}

// MARK: - Service

@Observable
final class JourneyService {
    private(set) var accountID: String?
    private(set) var states: [JourneyState] = []
    private(set) var syncError: String?

    @ObservationIgnored private weak var store: HabitStore?
    @ObservationIgnored private var indexListener: ListenerRegistration?
    @ObservationIgnored private var listeners: [String: [ListenerRegistration]] = [:]
    @ObservationIgnored private var journeys: [String: SharedJourney] = [:]
    @ObservationIgnored private var members: [String: [JourneyMember]] = [:]
    @ObservationIgnored private var completions: [String: [JourneyCompletion]] = [:]
    @ObservationIgnored private var syncedStreaks: [String: Int] = [:]

    private var db: Firestore { Firestore.firestore() }

    // Called whenever the signed-in account changes.
    func activate(account uid: String?, store: HabitStore) {
        guard uid != accountID else { return }
        stopListening()
        accountID = uid
        self.store = store
        store.completionObserver = nil
        guard let uid else { return }

        store.completionObserver = { [weak self] habit, day, done in
            self?.syncCompletion(of: habit, day: day, done: done)
        }
        indexListener = db.collection("users").document(uid).collection("journeys")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    journeyTrace("journey index listener failed: \((error as NSError).domain) \((error as NSError).code) \(error.localizedDescription)")
                    self.syncError = error.localizedDescription
                    return
                }
                let ids = Set(snapshot?.documents.map(\.documentID) ?? [])
                journeyTrace("journey index: \(ids.count) journeys")
                self.updateJourneyListeners(to: ids)
            }
    }

    func state(for journeyId: String) -> JourneyState? {
        states.first { $0.id == journeyId }
    }

    private var displayName: String {
        let name = store?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "صديقة" : name
    }

    // MARK: Listening

    private func stopListening() {
        indexListener?.remove()
        indexListener = nil
        listeners.values.flatMap { $0 }.forEach { $0.remove() }
        listeners = [:]
        journeys = [:]; members = [:]; completions = [:]; syncedStreaks = [:]
        states = []
        syncError = nil
    }

    private func updateJourneyListeners(to ids: Set<String>) {
        for gone in Set(listeners.keys).subtracting(ids) {
            listeners[gone]?.forEach { $0.remove() }
            listeners[gone] = nil
            journeys[gone] = nil; members[gone] = nil; completions[gone] = nil
        }
        for id in ids where listeners[id] == nil {
            let ref = db.collection("journeys").document(id)
            listeners[id] = [
                ref.addSnapshotListener { [weak self] snapshot, _ in
                    guard let self, let snapshot, let journey = Self.journey(from: snapshot) else { return }
                    self.journeys[id] = journey
                    self.publish()
                },
                ref.collection("members").addSnapshotListener { [weak self] snapshot, _ in
                    guard let self else { return }
                    self.members[id] = snapshot?.documents.map(Self.member(from:)) ?? []
                    self.publish()
                },
                ref.collection("completions").addSnapshotListener { [weak self] snapshot, _ in
                    guard let self else { return }
                    self.completions[id] = snapshot?.documents.compactMap { doc in
                        guard let uid = doc["uid"] as? String, let day = doc["day"] as? String else { return nil }
                        return JourneyCompletion(uid: uid, day: day)
                    } ?? []
                    self.publish()
                }
            ]
        }
        publish()
    }

    private func publish() {
        states = journeys.values
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            .map { journey in
                JourneyState(
                    journey: journey,
                    members: (members[journey.id] ?? []).sorted { ($0.joinedAt ?? .distantPast) < ($1.joinedAt ?? .distantPast) },
                    completions: completions[journey.id] ?? []
                )
            }
    }

    // MARK: Creating a journey and invites

    // Shares one of the user's habits as a new journey. The user is its first member.
    func createJourney(for habit: Habit, constellationIndex: Int) async throws -> String {
        guard let uid = accountID else { throw JourneyError.notSignedIn }
        let journeyRef = db.collection("journeys").document()
        let batch = db.batch()
        batch.setData([
            "habitTitle": habit.name,
            "habitIcon": habit.icon,
            "habitDays": habit.days.sorted(),
            "constellationIndex": constellationIndex,
            "createdBy": uid,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: journeyRef)
        batch.setData([
            "displayName": displayName,
            "role": "owner",
            "streak": habit.streak,
            "active": true,
            "joinedAt": FieldValue.serverTimestamp()
        ], forDocument: journeyRef.collection("members").document(uid))
        batch.setData(["joinedAt": FieldValue.serverTimestamp()],
                      forDocument: db.collection("users").document(uid).collection("journeys").document(journeyRef.documentID))
        journeyTrace("createJourney: committing \(journeyRef.documentID)")
        do {
            try await batch.commit()
        } catch {
            journeyTrace("createJourney failed: \((error as NSError).domain) \((error as NSError).code) \(error.localizedDescription)")
            throw error
        }
        journeyTrace("createJourney: done")

        store?.linkHabit(habit.id, toJourney: journeyRef.documentID)
        return journeyRef.documentID
    }

    // A new random invite to an existing journey, valid for 7 days.
    func createInvite(for journeyId: String) async throws -> InviteSummary {
        guard let uid = accountID else { throw JourneyError.notSignedIn }
        let journey: SharedJourney
        if let known = journeys[journeyId] {
            journey = known
        } else {
            let snapshot = try await db.collection("journeys").document(journeyId).getDocument()
            guard let loaded = Self.journey(from: snapshot) else { throw JourneyError.invalid }
            journey = loaded
        }

        let code = InviteCode.make()
        let expires = Date.now.addingTimeInterval(InviteCode.lifetime)
        journeyTrace("createInvite: writing invite for journey \(journeyId)")
        defer { journeyTrace("createInvite: finished") }
        try await db.collection("invites").document(code).setData([
            "journeyId": journeyId,
            "inviterUid": uid,
            "inviterName": displayName,
            "habitTitle": journey.habitTitle,
            "habitIcon": journey.habitIcon,
            "habitDays": journey.habitDays,
            "constellationIndex": journey.constellationIndex,
            "createdAt": FieldValue.serverTimestamp(),
            "expiresAt": Timestamp(date: expires),
            "revoked": false
        ])
        return InviteSummary(code: code, journeyId: journeyId, inviterUid: uid, inviterName: displayName,
                             habitTitle: journey.habitTitle, habitIcon: journey.habitIcon,
                             habitDays: journey.habitDays, constellationIndex: journey.constellationIndex,
                             expiresAt: expires, revoked: false)
    }

    // The user's own invites to a journey that can still be used.
    func activeInvites(for journeyId: String) async throws -> [InviteSummary] {
        guard let uid = accountID else { return [] }
        let snapshot = try await db.collection("invites")
            .whereField("inviterUid", isEqualTo: uid)
            .whereField("journeyId", isEqualTo: journeyId)
            .getDocuments()
        return snapshot.documents
            .compactMap(Self.invite(from:))
            .filter { !$0.revoked && !$0.isExpired }
            .sorted { $0.expiresAt > $1.expiresAt }
    }

    func revokeInvite(_ code: String) async throws {
        try await db.collection("invites").document(code).updateData(["revoked": true])
    }

    // MARK: Opening and accepting an invite

    func lookup(_ code: String) async throws -> InviteLookup {
        guard let uid = accountID else { throw JourneyError.notSignedIn }
        journeyTrace("lookup invite")
        let snapshot = try await db.collection("invites").document(code).getDocument()
        guard let invite = Self.invite(from: snapshot) else { return .invalid }
        if invite.revoked { return .revoked }
        if invite.isExpired { return .expired }

        let member = try await db.collection("journeys").document(invite.journeyId)
            .collection("members").document(uid).getDocument()
        if member.exists { return .alreadyMember(journeyId: invite.journeyId) }
        return .ready(invite)
    }

    // Joins atomically: tapping twice, opening the link again or the inviter
    // opening their own invite never adds a second membership.
    func accept(_ invite: InviteSummary) async throws -> InviteAcceptResult {
        guard let uid = accountID else { throw JourneyError.notSignedIn }
        journeyTrace("accept: starting transaction")
        let joined = try await Self.acceptTransaction(
            db: db, code: invite.code, uid: uid, displayName: displayName
        )
        switch joined {
        case .joined(let journeyId):
            store?.addSharedHabit(title: invite.habitTitle, icon: invite.habitIcon,
                                  days: Set(invite.habitDays), journeyID: journeyId)
            return .joined(journeyId: journeyId)
        case .already(let journeyId):
            return .alreadyMember(journeyId: journeyId)
        case .invalid: return .invalid
        case .expired: return .expired
        case .revoked: return .revoked
        }
    }

    private enum AcceptOutcome { case joined(String), already(String), invalid, expired, revoked }

    // Runs off the main actor: Firestore calls the transaction block on its own queue.
    nonisolated private static func acceptTransaction(
        db: Firestore, code: String, uid: String, displayName: String
    ) async throws -> AcceptOutcome {
        let inviteRef = db.collection("invites").document(code)
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let inviteSnap = try transaction.getDocument(inviteRef)
                guard inviteSnap.exists,
                      let journeyId = inviteSnap.get("journeyId") as? String else { return "invalid" }
                if inviteSnap.get("revoked") as? Bool ?? true { return "revoked" }
                guard let expires = (inviteSnap.get("expiresAt") as? Timestamp)?.dateValue(),
                      expires > .now else { return "expired" }

                let journeyRef = db.collection("journeys").document(journeyId)
                let memberRef = journeyRef.collection("members").document(uid)
                if try transaction.getDocument(memberRef).exists { return "already:" + journeyId }

                transaction.setData([
                    "displayName": displayName,
                    "role": "member",
                    "inviteCode": code,
                    "streak": 0,
                    "active": true,
                    "joinedAt": FieldValue.serverTimestamp()
                ], forDocument: memberRef)
                transaction.setData(["joinedAt": FieldValue.serverTimestamp()],
                                    forDocument: db.collection("users").document(uid)
                                        .collection("journeys").document(journeyId))
                return "joined:" + journeyId
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        let text = result as? String ?? "invalid"
        if text.hasPrefix("joined:") { return .joined(String(text.dropFirst(7))) }
        if text.hasPrefix("already:") { return .already(String(text.dropFirst(8))) }
        switch text {
        case "revoked": return .revoked
        case "expired": return .expired
        default: return .invalid
        }
    }

    // MARK: Leaving

    // The member is marked inactive; their past completions stay in the journey.
    func leave(_ journeyId: String) async throws {
        guard let uid = accountID else { throw JourneyError.notSignedIn }
        let journeyRef = db.collection("journeys").document(journeyId)
        try await journeyRef.collection("members").document(uid).updateData(["active": false])
        try await db.collection("users").document(uid).collection("journeys").document(journeyId).delete()
        if let habit = store?.habit(forJourney: journeyId) {
            store?.linkHabit(habit.id, toJourney: nil)
        }
    }

    // MARK: Syncing progress

    // Mirrors today's completion of a shared habit. The document id is uid_day,
    // so syncing again can never count the same day twice.
    private func syncCompletion(of habit: Habit, day: String, done: Bool) {
        guard let uid = accountID, let journeyId = habit.sharedJourneyID else { return }
        let journeyRef = db.collection("journeys").document(journeyId)
        let ref = journeyRef.collection("completions").document("\(uid)_\(day)")
        Task {
            do {
                if done {
                    try await ref.setData(["uid": uid, "day": day, "recordedAt": FieldValue.serverTimestamp()])
                } else {
                    try await ref.delete()
                }
                try await syncStreak(of: habit, journeyRef: journeyRef, uid: uid)
            } catch {
                journeyTrace("syncCompletion failed: \((error as NSError).code) \(error.localizedDescription)")
                syncError = error.localizedDescription
            }
        }
    }

    // The member's streak on the shared habit, computed from their own log.
    func syncStreaks() {
        guard let uid = accountID, let store else { return }
        for habit in store.habits {
            guard let journeyId = habit.sharedJourneyID else { continue }
            let ref = db.collection("journeys").document(journeyId)
            Task { try? await syncStreak(of: habit, journeyRef: ref, uid: uid) }
        }
    }

    private func syncStreak(of habit: Habit, journeyRef: DocumentReference, uid: String) async throws {
        let journeyId = journeyRef.documentID
        let current = store?.habits.first { $0.id == habit.id }?.streak ?? habit.streak
        guard syncedStreaks[journeyId] != current else { return }
        try await journeyRef.collection("members").document(uid).updateData(["streak": current])
        syncedStreaks[journeyId] = current
    }

    // MARK: Parsing

    nonisolated private static func journey(from snapshot: DocumentSnapshot) -> SharedJourney? {
        guard snapshot.exists,
              let title = snapshot.get("habitTitle") as? String,
              let createdBy = snapshot.get("createdBy") as? String else { return nil }
        return SharedJourney(
            id: snapshot.documentID,
            habitTitle: title,
            habitIcon: snapshot.get("habitIcon") as? String ?? "star",
            habitDays: snapshot.get("habitDays") as? [Int] ?? Array(0...6),
            constellationIndex: snapshot.get("constellationIndex") as? Int ?? 0,
            createdBy: createdBy,
            createdAt: (snapshot.get("createdAt") as? Timestamp)?.dateValue()
        )
    }

    nonisolated private static func member(from snapshot: QueryDocumentSnapshot) -> JourneyMember {
        JourneyMember(
            id: snapshot.documentID,
            displayName: snapshot.get("displayName") as? String ?? "صديقة",
            role: snapshot.get("role") as? String ?? "member",
            streak: snapshot.get("streak") as? Int ?? 0,
            active: snapshot.get("active") as? Bool ?? true,
            joinedAt: (snapshot.get("joinedAt") as? Timestamp)?.dateValue()
        )
    }

    nonisolated private static func invite(from snapshot: DocumentSnapshot) -> InviteSummary? {
        guard snapshot.exists,
              let journeyId = snapshot.get("journeyId") as? String,
              let inviterUid = snapshot.get("inviterUid") as? String,
              let expires = (snapshot.get("expiresAt") as? Timestamp)?.dateValue() else { return nil }
        return InviteSummary(
            code: snapshot.documentID,
            journeyId: journeyId,
            inviterUid: inviterUid,
            inviterName: snapshot.get("inviterName") as? String ?? "صديقة",
            habitTitle: snapshot.get("habitTitle") as? String ?? "",
            habitIcon: snapshot.get("habitIcon") as? String ?? "star",
            habitDays: snapshot.get("habitDays") as? [Int] ?? Array(0...6),
            constellationIndex: snapshot.get("constellationIndex") as? Int ?? 0,
            expiresAt: expires,
            revoked: snapshot.get("revoked") as? Bool ?? false
        )
    }
}
