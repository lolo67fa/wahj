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
    // Set by "start a new streak": the journey counts again from this day.
    var journeyStartDate: Date?
    // Days completed before the completion log existed (imported from older data).
    var baselineCompletedDays: Int?
    // Example habits for previews only, never part of a real account.
    var isDemo: Bool?

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

extension Habit: ProgressTrackable {
    var isDemoData: Bool { isDemo ?? false }
}

// Holds all habits and the completion log for the signed-in account and saves
// them to that account's own UserDefaults (on this device only; nothing is
// synced to Firebase). Points, unlocked constellations and streaks are always
// recomputed from the log, so undoing a completion can't leave stale points.
@Observable
final class HabitStore {
    var habits: [Habit] = [] {
        didSet { if canPersist { save() } }
    }
    // True only while a signed-in account's data is loaded.
    @ObservationIgnored private var canPersist = false
    @ObservationIgnored private var includeDemo = false
    @ObservationIgnored private var defaults: UserDefaults = .standard

    // Firebase UID of the account whose data is loaded (nil when signed out).
    private(set) var accountID: String?
    private(set) var log = HabitLog()

    // Computed from the log by recompute().
    private(set) var constellations = HabitProgress.Constellations()
    private(set) var appStreak = 0
    // The real current day (not the day selected in the UI).
    private(set) var today = Calendar.current.startOfDay(for: .now)

    // The habit to show on the "missed habit" screen, if any.
    var missedHabit: Habit?
    // Set when a habit reaches its full duration, to show a congratulations alert.
    var justFinished: Habit?
    // Missed habits the user closed with X button; asked again next time the app opens.
    private var skippedMissedIDs: Set<UUID> = []

    private let storageKey = "savedHabits.v2"
    private let logKey = "habitLog.v1"
    private let saverKey = "lastStreakSaverDate"

    // Nothing is loaded until an account signs in; see activate(account:).
    init() {
        UNUserNotificationCenter.current().delegate = ReminderPresenter.shared
    }

    // For SwiftUI previews only: example habits, marked as demo, never saved.
    init(previewHabits: [Habit]) {
        includeDemo = true
        habits = previewHabits
        recompute()
    }

    static var preview: HabitStore { HabitStore(previewHabits: samples) }

    // MARK: - Accounts

    // Each Firebase account keeps its data in its own UserDefaults suite.
    static func accountDefaults(for accountID: String) -> UserDefaults {
        // suiteName only returns nil for the app's own bundle ID or the global domain.
        UserDefaults(suiteName: "wahj.account.\(accountID)")!
    }

    // Loads the data of the account that just signed in (or clears it on sign-out).
    func activate(account newAccountID: String?) {
        guard newAccountID != accountID else { return }

        // Reminders belong to the previous account; don't show its habit names to the next one.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        canPersist = false
        accountID = newAccountID
        habits = []
        log = HabitLog()
        missedHabit = nil
        justFinished = nil
        skippedMissedIDs = []

        guard let newAccountID else {
            recompute()
            return
        }
        defaults = Self.accountDefaults(for: newAccountID)
        habits = loadHabits()
        log = loadLog()
        canPersist = true
        checkForNewDay()
        for habit in habits {
            Task { await ReminderScheduler.schedule(habit) }
        }
    }

    // Adds habits from data saved on this device before accounts were separated.
    // Only called after the user agrees (see LegacyHabitMigration).
    func importLegacyHabits(_ legacy: [Habit]) {
        guard canPersist else { return }
        let existing = Set(habits.map(\.id))
        let new = legacy.filter { !existing.contains($0.id) }.map { old -> Habit in
            var habit = old
            // Their earlier progress has no log entries: keep it as the journey's baseline
            // (shown on the habit card), without inventing points or streak days.
            habit.baselineCompletedDays = old.completedDays
            habit.todayCount = 0
            return habit
        }
        habits.append(contentsOf: new)
        recompute()
        for habit in new {
            Task { await ReminderScheduler.schedule(habit) }
        }
    }

    // MARK: - Reading progress

    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        let key = DayKey.key(for: date)
        return log.records.contains { $0.habitID == habit.id && $0.day == key }
    }

    // Whether the habit is due that day (its weekday, after it was created, journey not finished).
    func isDue(_ habit: Habit, on date: Date) -> Bool {
        timeline(for: habit).isDue(date, key: DayKey.key(for: date))
    }

    // Only today's completions can be changed for now; past days are read-only
    // and future days can't be completed.
    func canEditCompletion(on date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: .now)
    }

    func constellationPoints(_ index: Int) -> Int {
        constellations.points.indices.contains(index) ? constellations.points[index] : 0
    }

    func isConstellationUnlocked(_ index: Int) -> Bool {
        constellations.isUnlocked(index)
    }

    private func timeline(for habit: Habit) -> HabitProgress.Timeline {
        HabitProgress.Timeline(habit: habit, log: log, includeDemo: includeDemo, calendar: DayKey.calendar())
    }

    // Everything derived from the log: journey days, streaks, points, unlocked constellations.
    private func recompute() {
        let calendar = DayKey.calendar()
        today = Calendar.current.startOfDay(for: .now)

        var updated = habits
        for index in updated.indices {
            let line = timeline(for: updated[index])
            updated[index].completedDays = min(line.journeyCompletions(), updated[index].durationDays)
            updated[index].streakCount = HabitProgress.streak(timelines: [line], today: .now, calendar: calendar)
            if let lastKey = line.completedKeys.last,
               let lastRecord = log.records.last(where: { $0.habitID == updated[index].id && $0.day == lastKey }) {
                updated[index].lastCompletedDate = lastRecord.recordedAt
            } else if updated[index].baselineCompletedDays == nil {
                updated[index].lastCompletedDate = nil
            }
        }
        if updated != habits { habits = updated }

        constellations = HabitProgress.constellations(from: log.records, includeDemo: includeDemo)
        appStreak = HabitProgress.appStreak(habits: habits, log: log, today: .now,
                                            calendar: calendar, includeDemo: includeDemo)
    }

    // MARK: - Completion log

    // Adds today's completion once; pressing again or relaunching never adds a second one.
    private func addCompletion(at index: Int) {
        let habit = habits[index]
        let key = DayKey.key(for: .now)
        guard !log.records.contains(where: { $0.habitID == habit.id && $0.day == key }) else { return }

        let selected = defaults.object(forKey: "selectedStarIndex") as? Int ?? 0
        let constellation = min(max(habit.constellationIndex ?? selected, 0), HabitProgress.constellationCount - 1)
        log.records.append(CompletionRecord(
            habitID: habit.id, day: key, constellationIndex: constellation,
            recordedAt: .now, isDemo: habit.isDemo
        ))
        saveLog()
    }

    private func removeCompletion(at index: Int) {
        let id = habits[index].id
        let key = DayKey.key(for: .now)
        log.records.removeAll { $0.habitID == id && $0.day == key }
        saveLog()
    }

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
        updated.journeyStartDate = old.journeyStartDate
        updated.baselineCompletedDays = old.baselineCompletedDays
        updated.isDemo = old.isDemo
        updated.createdAt = old.createdAt
        if habit.days != old.days && !hadMissed {
            updated.lastResolvedDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)
        }
        habits[index] = updated

        // A new daily goal can change whether today counts as done.
        let wasDone = old.isDoneToday && old.todayCount > 0
        let isDone = habits[index].isDoneToday && habits[index].todayCount > 0
        if wasDone && !isDone {
            removeCompletion(at: index)
        } else if !wasDone && isDone {
            habits[index].lastLogDate = .now
            addCompletion(at: index)
        }
        recompute()

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

    // Its log entries stay, so points already earned aren't taken away.
    func delete(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        ReminderScheduler.cancel(habit)
        recompute()
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
        let wasFinished = habits[index].isFinished
        addCompletion(at: index)
        recompute()

        if habits[index].isFinished && !wasFinished {
            justFinished = habits[index]
            ReminderScheduler.cancel(habits[index])
        }
    }

    private func uncompleteToday(at index: Int) {
        let wasFinished = habits[index].isFinished
        removeCompletion(at: index)
        recompute()

        if wasFinished && !habits[index].isFinished {
            let habit = habits[index]
            Task { await ReminderScheduler.schedule(habit) }
        }
    }

    // MARK: - New day & missed days

    // Called when the app opens, comes back to the front, or passes midnight:
    // resets today's counters and asks about any missed habit again.
    func checkForNewDay() {
        resetCountsIfNewDay()
        recompute()
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
        guard let last = defaults.object(forKey: saverKey) as? Date else { return true }
        return !Calendar.current.isDate(last, equalTo: .now, toGranularity: .month)
    }

    // "Use this month's chance": keep the progress and forgive the missed day.
    func useSaver(_ habit: Habit) {
        guard canUseSaver else { return }
        if canPersist { defaults.set(Date.now, forKey: saverKey) }
        forgiveMissedDays(of: habit)
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
            // The journey starts again today; earlier log entries (and their points) stay.
            habits[index].journeyStartDate = Calendar.current.startOfDay(for: .now)
            habits[index].baselineCompletedDays = 0
        }
        recompute()
        // The next missed habit (if any) is shown after this page closes; see RootView.
    }

    // The saver forgives the missed due days (up to yesterday), so they don't break the
    // streak. It is still limited to once per month by canUseSaver.
    private func forgiveMissedDays(of habit: Habit) {
        let calendar = Calendar.current
        let line = timeline(for: habit)
        let lastHandled = [habit.createdAt, habit.lastCompletedDate, habit.lastResolvedDate]
            .compactMap { $0 }.max() ?? .now
        guard var day = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastHandled)) else { return }
        let today = calendar.startOfDay(for: .now)
        while day < today {
            let key = DayKey.key(for: day)
            if line.isDue(day, key: key) && !line.isCompleted(key) && !line.isForgiven(key) {
                log.forgiven.append(ForgivenDay(habitID: habit.id, day: key))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        saveLog()
    }

    // MARK: - Saving

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func saveLog() {
        guard canPersist, let data = try? JSONEncoder().encode(log) else { return }
        defaults.set(data, forKey: logKey)
    }

    private func loadHabits() -> [Habit] {
        guard let data = defaults.data(forKey: storageKey),
              var saved = try? JSONDecoder().decode([Habit].self, from: data) else { return [] }
        // Habits saved before missed-day tracking existed start counting from now.
        for index in saved.indices where saved[index].createdAt == nil {
            saved[index].createdAt = .now
        }
        return saved
    }

    private func loadLog() -> HabitLog {
        guard let data = defaults.data(forKey: logKey),
              let saved = try? JSONDecoder().decode(HabitLog.self, from: data) else { return HabitLog() }
        return saved
    }

    static let samples: [Habit] = [
        Habit(name: "قراءة ١٠ صفحات", icon: "book", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 21, dailyGoal: 1, completedDays: 4,
              favorite: true, streakCount: 4, baselineCompletedDays: 4, isDemo: true),
        Habit(name: "شرب الماء", icon: "waterbottle.fill", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 14, dailyGoal: 15, completedDays: 5, streakCount: 5,
              baselineCompletedDays: 5, isDemo: true),
        Habit(name: "مشي ٢٠ دقيقة", icon: "figure.walk", days: Set(0...6), reminderEnabled: false,
              reminderTime: .now, durationDays: 7, dailyGoal: 1, todayCount: 1, completedDays: 3,
              lastLogDate: .now, lastCompletedDate: .now, streakCount: 3,
              baselineCompletedDays: 3, isDemo: true)
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
