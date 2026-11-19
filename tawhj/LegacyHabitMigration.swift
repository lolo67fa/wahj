//
//  LegacyHabitMigration.swift
//  tawhj
//
//  Before the screens were merged, the onboarding Add Habit page saved habits
//  as `SavedHabit` under the "habitsData" key, separate from the habits page.
//  This moves any of those into the shared HabitStore once, so they show up
//  on the habits page.
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
    private static let key = "habitsData"

    static func takeSavedHabits() -> [Habit] {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: key), !data.isEmpty,
              let saved = try? JSONDecoder().decode([SavedHabit].self, from: data)
        else { return [] }

        defaults.removeObject(forKey: key)

        return saved.map { old in
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
}
