import SwiftUI
import UserNotifications

// A single habit the user is tracking.
// `dailyGoal` is how many times per day (e.g. drink water 15 times),
// `todayCount` is how many times they've logged it today.
struct Habit: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var icon: String
    var days: Set<Int>          // 0 = Saturday ... 6 = Friday
    var reminderEnabled: Bool
    var reminderTime: Date
    var durationDays: Int
    var dailyGoal: Int
    var todayCount = 0
    var completedDays = 0
    var lastLogDate: Date?

    // Used to detect missed days. Optional so older saved habits still load.
    var createdAt: Date? = .now
    var lastCompletedDate: Date?
    var previousCompletedDate: Date?   // restored when today's completion is undone
    var lastResolvedDate: Date?        // last time a missed day was handled
    // Optional so habits saved before these existed still load.
    var favorite: Bool?
    var streakCount: Int?              // completed days in a row (reset by "start a new streak")
    // The constellation chosen on the star selection screen when the habit was created.
    var constellationIndex: Int?

    var isFavorite: Bool { favorite ?? false }
    var streak: Int { streakCount ?? 0 }

    var isDoneToday: Bool { todayCount >= dailyGoal }
    var isFinished: Bool { completedDays >= durationDays }
    var isScheduledToday: Bool { days.contains(Habit.dayIndex(of: .now)) }
    var canLogToday: Bool { isScheduledToday && !isFinished && !isDoneToday }
    var todayProgress: Double { Double(todayCount) / Double(max(dailyGoal, 1)) }

    // Converts a date to our day index (0 = Saturday ... 6 = Friday).
    // Calendar weekdays are 1 = Sunday ... 7 = Saturday, so `% 7` maps Saturday to 0.
    static func dayIndex(of date: Date) -> Int {
        Calendar.current.component(.weekday, from: date) % 7
    }
}

// Holds all habits and saves them to UserDefaults so they survive app relaunches.
@Observable
final class HabitStore {
    var habits: [Habit] = [] {
        didSet { if !isPreview { save() } }
    }
    @ObservationIgnored private var isPreview = false

    // The habit to show on the "missed habit" screen, if any.
    var missedHabit: Habit?
    // Set when a habit reaches its full duration, to show a congratulations alert.
    var justFinished: Habit?
    // Missed habits the user closed with X button; asked again next time the app opens.
    private var skippedMissedIDs: Set<UUID> = []

    private let storageKey = "savedHabits.v2"
    private let saverKey = "lastStreakSaverDate"

    init() {
        UNUserNotificationCenter.current().delegate = ReminderPresenter.shared
        if UserDefaults.standard.data(forKey: storageKey) != nil {
            load()
        }
        // Habits saved by the onboarding Add Habit page before the screens were merged.
        let legacy = LegacyHabitMigration.takeSavedHabits()
        if !legacy.isEmpty {
            habits.append(contentsOf: legacy)
            save()
        }
        checkForNewDay()
    }

    // For SwiftUI previews only: starts with example habits and doesn't touch saved data.
    init(previewHabits: [Habit]) {
        isPreview = true
        habits = previewHabits
    }

    static var preview: HabitStore { HabitStore(previewHabits: samples) }

    // MARK: - Adding, editing, deleting

    func add(_ habit: Habit) {
        habits.append(habit)
        Task { await ReminderScheduler.schedule(habit) }
    }

    // Saves edited settings and keeps today's progress consistent with them.
    func update(_ habit: Habit) {
        resetCountsIfNewDay()
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let old = habits[index]

        // Adding days shouldn't turn past days into "missed" ones.
        // Only forgive the past if nothing was actually missed before the edit.
        let hadMissed = hasMissedDay(old)

        var updated = habit
        // Progress always comes from the stored habit, not the edit-screen copy.
        updated.todayCount = min(old.todayCount, habit.dailyGoal)
        updated.completedDays = min(old.completedDays, habit.durationDays)
        updated.lastLogDate = old.lastLogDate
        updated.lastCompletedDate = old.lastCompletedDate
        updated.previousCompletedDate = old.previousCompletedDate
        updated.lastResolvedDate = old.lastResolvedDate
        updated.streakCount = old.streakCount
        updated.favorite = old.favorite
        if habit.days != old.days && !hadMissed {
            updated.lastResolvedDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)
        }
        habits[index] = updated

        // A new daily goal can change whether today counts as done.
        let wasDone = old.isDoneToday && old.todayCount > 0
        let isDone = habits[index].isDoneToday && habits[index].todayCount > 0
        if wasDone && !isDone {
            StarProgress.removePoints(StarProgress.pointsPerHabit)
            habits[index].lastCompletedDate = old.previousCompletedDate
            habits[index].completedDays = max(habits[index].completedDays - 1, 0)
            habits[index].streakCount = max(habits[index].streak - 1, 0)
        } else if !wasDone && isDone {
            StarProgress.awardPoints(StarProgress.pointsPerHabit)
            habits[index].previousCompletedDate = old.lastCompletedDate
            habits[index].lastCompletedDate = .now
            habits[index].completedDays = min(habits[index].completedDays + 1, habits[index].durationDays)
            habits[index].streakCount = habits[index].streak + 1
        }

        // A shorter duration can finish the journey right away.
        if habits[index].isFinished && !old.isFinished {
            justFinished = habits[index]
        }

        let saved = habits[index]
        Task { await ReminderScheduler.schedule(saved) }
    }

    // The star on the left of each card.
    func toggleFavorite(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index].favorite = !habits[index].isFavorite
    }

    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        ReminderScheduler.cancel(habit)
    }

    // MARK: - Logging

    // The + button: logs one more time for today (e.g. "I drank a glass of water").
    func logOnce(_ habit: Habit) {
        resetCountsIfNewDay()
        guard let index = habits.firstIndex(where: { $0.id == habit.id }),
              habits[index].canLogToday else { return }

        habits[index].todayCount += 1
        habits[index].lastLogDate = .now
        if habits[index].isDoneToday {
            completeToday(at: index)
        }
    }

    // Undoes the last + tap (or today's star).
    func undoOnce(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }),
              habits[index].todayCount > 0 else { return }

        if habits[index].isDoneToday {
            uncompleteToday(at: index)
        }
        habits[index].todayCount -= 1
    }

    // The star: marks the whole habit as done (or not done) for today.
    func toggleDone(_ habit: Habit) {
        resetCountsIfNewDay()
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }

        if habits[index].isDoneToday {
            uncompleteToday(at: index)
            habits[index].todayCount = 0
        } else if habits[index].canLogToday {
            habits[index].todayCount = habits[index].dailyGoal
            habits[index].lastLogDate = .now
            completeToday(at: index)
        }
    }

    private func completeToday(at index: Int) {
        StarProgress.awardPoints(StarProgress.pointsPerHabit)
        habits[index].previousCompletedDate = habits[index].lastCompletedDate
        habits[index].lastCompletedDate = .now
        habits[index].completedDays = min(habits[index].completedDays + 1, habits[index].durationDays)
        habits[index].streakCount = habits[index].streak + 1

        if habits[index].isFinished {
            justFinished = habits[index]
            ReminderScheduler.cancel(habits[index])
        }
    }

    private func uncompleteToday(at index: Int) {
        let wasFinished = habits[index].isFinished
        StarProgress.removePoints(StarProgress.pointsPerHabit)
        habits[index].lastCompletedDate = habits[index].previousCompletedDate
        habits[index].completedDays = max(habits[index].completedDays - 1, 0)
        habits[index].streakCount = max(habits[index].streak - 1, 0)

        if wasFinished {
            let habit = habits[index]
            Task { await ReminderScheduler.schedule(habit) }
        }
    }

    // MARK: - New day & missed days

    // Called when the app opens, comes back to the front, or passes midnight:
    // resets today's counters and asks about any missed habit again.
    func checkForNewDay() {
        resetCountsIfNewDay()
        skippedMissedIDs = []
        showNextMissed()
    }

    // Today's counters start from zero each new day.
    private func resetCountsIfNewDay() {
        for index in habits.indices {
            if let last = habits[index].lastLogDate, !Calendar.current.isDateInToday(last),
               habits[index].todayCount != 0 {
                habits[index].todayCount = 0
            }
        }
    }

    // Shows the next missed habit (if any) that the user hasn't closed with X button.
    func showNextMissed() {
        missedHabit = habits.first { hasMissedDay($0) && !skippedMissedIDs.contains($0.id) }
    }

    // X button on the missed page: don't ask again until the app is opened next time.
    func skipMissed(_ habit: Habit) {
        skippedMissedIDs.insert(habit.id)
    }

    // A habit is missed if one of its chosen days passed (before today) without being completed.
    private func hasMissedDay(_ habit: Habit) -> Bool {
        guard !habit.isFinished else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lastHandled = [habit.createdAt, habit.lastCompletedDate, habit.lastResolvedDate]
            .compactMap { $0 }
            .max() ?? .now

        guard var day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastHandled)) else {
            return false
        }
        while day < today {
            if habit.days.contains(Habit.dayIndex(of: day)) { return true }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return false
    }

    // The streak saver can be used once per calendar month.
    var canUseSaver: Bool {
        guard let last = UserDefaults.standard.object(forKey: saverKey) as? Date else { return true }
        return !Calendar.current.isDate(last, equalTo: .now, toGranularity: .month)
    }

    // "Use this month's chance": keep the progress and forgive the missed day.
    func useSaver(_ habit: Habit) {
        guard canUseSaver else { return }
        UserDefaults.standard.set(Date.now, forKey: saverKey)
        resolveMissed(habit, resetProgress: false)
    }

    // "Start a new streak": progress goes back to zero.
    func restart(_ habit: Habit) {
        resolveMissed(habit, resetProgress: true)
    }

    private func resolveMissed(_ habit: Habit, resetProgress: Bool) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        // Mark everything up to yesterday as handled.
        habits[index].lastResolvedDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)
        if resetProgress {
            habits[index].completedDays = 0
            habits[index].streakCount = 0
        }
        // The next missed habit (if any) is shown after this page closes; see RootView.
    }

    // MARK: - Saving

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var saved = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        // Habits saved before missed-day tracking existed start counting from now.
        for index in saved.indices where saved[index].createdAt == nil {
            saved[index].createdAt = .now
        }
        habits = saved
    }

    static let samples: [Habit] = [
        Habit(name: "قراءة ١٠ صفحات", icon: "book", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 21, dailyGoal: 1, completedDays: 4,
              favorite: true, streakCount: 4),
        Habit(name: "شرب الماء", icon: "waterbottle.fill", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 14, dailyGoal: 15, completedDays: 5, streakCount: 5),
        Habit(name: "مشي ٢٠ دقيقة", icon: "figure.walk", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 7, dailyGoal: 1, todayCount: 1, completedDays: 3,
              lastLogDate: .now, lastCompletedDate: .now, streakCount: 3)
    ]
}

// By default iOS hides notifications while the app is open.
// This makes reminders show as a banner (with sound) even then.
final class ReminderPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

// Schedules a repeating local notification on each chosen day at the reminder time.
enum ReminderScheduler {
    static func schedule(_ habit: Habit) async {
        cancel(habit)
        guard habit.reminderEnabled, !habit.isFinished else { return }

        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }

        let time = Calendar.current.dateComponents([.hour, .minute], from: habit.reminderTime)
        for day in habit.days {
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            // Our index 0 = Saturday (weekday 7); 1...6 = Sunday...Friday (weekday 1...6).
            components.weekday = day == 0 ? 7 : day

            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = "حان وقت عادتك"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifier(for: habit, day: day),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            )
            try? await center.add(request)
        }
    }

    static func cancel(_ habit: Habit) {
        let ids = (0...6).map { identifier(for: habit, day: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func identifier(for habit: Habit, day: Int) -> String {
        "\(habit.id.uuidString)-\(day)"
    }
}

// Formats numbers with Arabic digits (١٢٣) to match the design.
func arabicNumber(_ value: Int) -> String {
    value.formatted(.number.locale(Locale(identifier: "ar@numbers=arab")))
}
