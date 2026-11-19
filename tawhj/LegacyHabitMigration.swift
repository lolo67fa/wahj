//
//  LegacyHabitMigration.swift
//  tawhj
//
//  Before accounts were separated, habits were saved in the app's shared
//  UserDefaults with no owner:
//    • "habitsData"     — the first onboarding Add Habit page (SavedHabit)
//    • "savedHabits.v2" — the habits page (Habit)
//  That data is never deleted and never given to an account automatically.
//  A signed-in user is asked once; if they agree it is copied into their
//  account and marked as claimed so no other account is offered it.
//

import Foundation

struct SavedHabit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var icon: String
    var weekdays: [Int]          // Calendar weekdays: Sunday = 1 ... Saturday = 7
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var duration: Int
    var startDate: Date
    var constellationIndex: Int
}

enum LegacyHabitMigration {
    private static let habitsKey = "savedHabits.v2"
    private static let onboardingHabitsKey = "habitsData"
    // In the shared defaults: the account that took the device's old data.
    private static let claimedKey = "legacyLocalData.claimedByAccount"
    // In an account's defaults: that account said no.
    private static let declinedKey = "legacyLocalData.declined"
    // Settings that were also stored without an owner.
    private static let settingKeys = ["displayName", "hasCompletedOnboarding",
                                      "selectedStarIndex", "selectedAppearance"]

    // True when this device has unowned habits and this account hasn't answered yet.
    static func hasUnclaimedData(for account: UserDefaults) -> Bool {
        let shared = UserDefaults.standard
        guard shared.string(forKey: claimedKey) == nil,
              !account.bool(forKey: declinedKey) else { return false }
        return !legacyHabits().isEmpty
    }

    static func legacyHabits() -> [Habit] {
        let shared = UserDefaults.standard
        var result: [Habit] = []

        if let data = shared.data(forKey: habitsKey),
           let saved = try? JSONDecoder().decode([Habit].self, from: data) {
            result += saved
        }

        if let data = shared.data(forKey: onboardingHabitsKey), !data.isEmpty,
           let saved = try? JSONDecoder().decode([SavedHabit].self, from: data) {
            let known = Set(result.map(\.id))
            result += saved.filter { !known.contains($0.id) }.map(habit(from:))
        }
        return result
    }

    // The user agreed: copy (not move) the old data into their account.
    static func claim(accountID: String, account: UserDefaults, into store: HabitStore) {
        let shared = UserDefaults.standard
        store.importLegacyHabits(legacyHabits())

        for key in settingKeys where account.object(forKey: key) == nil {
            if let value = shared.object(forKey: key) {
                account.set(value, forKey: key)
            }
        }
        shared.set(accountID, forKey: claimedKey)
    }

    static func decline(account: UserDefaults) {
        account.set(true, forKey: declinedKey)
    }

    private static func habit(from old: SavedHabit) -> Habit {
        Habit(
            id: old.id,
            name: old.name,
            icon: old.icon,
            // Calendar weekday % 7 gives the store's index (0 = Saturday ... 6 = Friday).
            days: Set(old.weekdays.map { $0 % 7 }),
            reminderEnabled: old.reminderEnabled,
            reminderTime: Calendar.current.date(
                bySettingHour: old.reminderHour,
                minute: old.reminderMinute,
                second: 0,
                of: .now
            ) ?? .now,
            durationDays: old.duration,
            dailyGoal: 1,
            createdAt: old.startDate,
            constellationIndex: old.constellationIndex
        )
    }
}
