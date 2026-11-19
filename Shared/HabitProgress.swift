//
//  HabitProgress.swift
//  Shared
//
//  The completion log and everything computed from it: constellation points,
//  which constellations are unlocked, the app streak and each habit's streak.
//  Foundation only, so the rules can be tested without the UI.
//

import Foundation

// MARK: - Day keys

// One calendar day in the device's local time zone, stored as "yyyy-MM-dd".
// A fixed Gregorian calendar keeps the key stable even if the user switches
// the device to the Hijri calendar; the day itself still follows local time.
enum DayKey {
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func key(for date: Date, calendar: Calendar = DayKey.calendar()) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // Our weekday index: 0 = Saturday ... 6 = Friday (same as Habit.days).
    static func weekdayIndex(of date: Date, calendar: Calendar = DayKey.calendar()) -> Int {
        calendar.component(.weekday, from: date) % 7
    }
}

// MARK: - Log

// One completed day of one habit. At most one record per habit per day.
struct CompletionRecord: Codable, Hashable {
    var habitID: UUID
    var day: String                 // DayKey
    var constellationIndex: Int     // where the points go first (kept even if the selection changes)
    var recordedAt: Date
    // Example data for previews. Never counted in a real account.
    var isDemo: Bool?

    var isUserCompletion: Bool { !(isDemo ?? false) }
}

// A missed day that the monthly streak saver forgave.
struct ForgivenDay: Codable, Hashable {
    var habitID: UUID
    var day: String
}

struct HabitLog: Codable, Equatable {
    var records: [CompletionRecord] = []
    var forgiven: [ForgivenDay] = []
}

// What the progress rules need to know about a habit.
protocol ProgressTrackable {
    var id: UUID { get }
    var days: Set<Int> { get }
    var createdAt: Date? { get }
    var durationDays: Int { get }
    // Set by "start a new streak": the journey counts again from this day.
    var journeyStartDate: Date? { get }
    // Days completed before the completion log existed (imported data).
    var baselineCompletedDays: Int? { get }
    var isDemoData: Bool { get }
}

// MARK: - Rules

enum HabitProgress {
    static let pointsPerCompletion = 5
    static let pointsPerConstellation = 100
    static let constellationCount = 6

    // MARK: Constellations

    struct Constellations: Equatable {
        var points: [Int] = Array(repeating: 0, count: HabitProgress.constellationCount)
        // Points earned after every constellation was full (nothing left to fill).
        var surplus = 0

        func isComplete(_ index: Int) -> Bool {
            points.indices.contains(index) && points[index] >= HabitProgress.pointsPerConstellation
        }

        // Only the first is open at the start; each full one opens the next.
        func isUnlocked(_ index: Int) -> Bool {
            guard points.indices.contains(index) else { return false }
            return index == 0 || isComplete(index - 1)
        }

        var total: Int { points.reduce(0, +) }
        var unlockedCount: Int { points.indices.filter(isUnlocked).count }
        var completedCount: Int { points.indices.filter(isComplete).count }
    }

    // Replays the log in order. Each completion adds 5 points to the
    // constellation it was recorded for. A full constellation passes the rest
    // on to the next one in order; no constellation goes past 100.
    static func constellations(from records: [CompletionRecord], includeDemo: Bool = false) -> Constellations {
        var state = Constellations()
        let ordered = records
            .filter { includeDemo || $0.isUserCompletion }
            .sorted { ($0.day, $0.recordedAt) < ($1.day, $1.recordedAt) }

        for record in ordered {
            var remaining = pointsPerCompletion
            while remaining > 0 {
                guard let index = target(preferred: record.constellationIndex, in: state) else {
                    state.surplus += remaining
                    break
                }
                let added = min(remaining, pointsPerConstellation - state.points[index])
                state.points[index] += added
                remaining -= added
            }
        }
        return state
    }

    private static func target(preferred: Int, in state: Constellations) -> Int? {
        let count = constellationCount
        let firstOpen = (0..<count).first { !state.isComplete($0) }
        var index = min(max(preferred, 0), count - 1)

        // A constellation that is locked right now (e.g. after an undo) can't
        // take points; they go to the first one that still has room.
        if !state.isUnlocked(index) {
            guard let firstOpen else { return nil }
            index = firstOpen
        }
        while index < count && state.isComplete(index) {
            index += 1
        }
        return index < count ? index : firstOpen
    }

    // MARK: Days

    // One habit's history, ready for day-by-day questions.
    struct Timeline {
        let habitID: UUID
        let days: Set<Int>
        let startKey: String
        let journeyStartKey: String?
        let durationDays: Int
        let baseline: Int
        let completedKeys: [String]      // sorted
        let completedSet: Set<String>
        let forgivenSet: Set<String>
        let calendar: Calendar

        init<H: ProgressTrackable>(habit: H, log: HabitLog, includeDemo: Bool, calendar: Calendar) {
            habitID = habit.id
            days = habit.days
            startKey = DayKey.key(for: habit.createdAt ?? .distantPast, calendar: calendar)
            journeyStartKey = habit.journeyStartDate.map { DayKey.key(for: $0, calendar: calendar) }
            durationDays = habit.durationDays
            baseline = habit.baselineCompletedDays ?? 0
            let keys = log.records
                .filter { $0.habitID == habit.id && (includeDemo || $0.isUserCompletion) }
                .map(\.day)
            completedSet = Set(keys)
            completedKeys = completedSet.sorted()
            forgivenSet = Set(log.forgiven.filter { $0.habitID == habit.id }.map(\.day))
            self.calendar = calendar
        }

        func isCompleted(_ key: String) -> Bool { completedSet.contains(key) }
        func isForgiven(_ key: String) -> Bool { forgivenSet.contains(key) }

        // Completed days in the current journey, counted before `key` (or all when nil).
        func journeyCompletions(before key: String? = nil) -> Int {
            // A day on/after "start a new streak" belongs to the new journey,
            // which starts from zero (no imported baseline).
            func isBeforeKey(_ day: String) -> Bool {
                guard let key else { return true }
                return day < key
            }
            if let restart = journeyStartKey, key.map({ $0 >= restart }) ?? true {
                return completedKeys.filter { $0 >= restart && isBeforeKey($0) }.count
            }
            let count = completedKeys.filter { $0 >= startKey && isBeforeKey($0) }.count
            return count + baseline
        }

        // Due on a day: on or after the start, on one of its chosen weekdays,
        // and the journey wasn't already finished before that day.
        func isDue(_ date: Date, key: String) -> Bool {
            guard key >= startKey,
                  days.contains(DayKey.weekdayIndex(of: date, calendar: calendar)) else { return false }
            return journeyCompletions(before: key) < durationDays
        }
    }

    // Streak over a set of timelines: consecutive due days on which every due
    // habit was completed (or forgiven by the saver). Days with nothing due
    // are skipped. Today only counts once it's complete, and never breaks it.
    static func streak(timelines: [Timeline], today: Date, calendar: Calendar) -> Int {
        guard !timelines.isEmpty,
              let earliest = timelines.map(\.startKey).min() else { return 0 }

        var day = calendar.startOfDay(for: today)
        var streak = 0
        var isToday = true
        var steps = 0

        while steps < 3_660 {
            let key = DayKey.key(for: day, calendar: calendar)
            if key < earliest { break }

            let due = timelines.filter { $0.isDue(day, key: key) }
            if !due.isEmpty {
                if due.allSatisfy({ $0.isCompleted(key) }) {
                    streak += 1
                } else if due.allSatisfy({ $0.isCompleted(key) || $0.isForgiven(key) }) {
                    // Forgiven by the monthly saver: keeps the streak without adding a day.
                } else if !isToday {
                    break
                }
            }

            isToday = false
            steps += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    static func appStreak<H: ProgressTrackable>(
        habits: [H], log: HabitLog, today: Date,
        calendar: Calendar = DayKey.calendar(), includeDemo: Bool = false
    ) -> Int {
        let timelines = habits
            .filter { includeDemo || !$0.isDemoData }
            .map { Timeline(habit: $0, log: log, includeDemo: includeDemo, calendar: calendar) }
        return streak(timelines: timelines, today: today, calendar: calendar)
    }
}
