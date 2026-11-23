//
//  NujaimaNotifications.swift
//  Shared
//
//  Notifications in Nujaima's voice, built from the user's real progress.
//
//  What is scheduled (for the next 7 days, rebuilt whenever habits or
//  completions change and when the app comes back to the front):
//    • reminder  — at the time the user chose for a habit
//    • evening   — 8:00 PM, for due habits that have no reminder time
//    • streak    — 9:30 PM today, only if today isn't complete and there is a streak to keep
//    • miss you  — 7 days after the last time the app was opened
//  Nothing is sent for a habit that is already done, finished or not due that day.
//  Every notification carries a picture of Nujaima (the app icon shows too).
//

import SwiftUI
import UserNotifications

// MARK: - Plan

struct NotificationItem: Equatable {
    enum Kind: String { case reminder, evening, streak, missYou }

    let id: String
    let kind: Kind
    let date: Date
    let title: String
    let body: String

    // Nujaima's expression for this kind of message.
    var imageName: String {
        switch kind {
        case .reminder: return "starWink"
        case .evening, .streak: return "starCharacter"
        case .missYou: return "starSleeping"
        }
    }
}

enum NotificationPlanner {
    static let idPrefix = "wahj.nujaima."
    static let eveningTime = (hour: 20, minute: 0)
    static let streakTime = (hour: 21, minute: 30)
    static let missYouAfterDays = 7
    static let maxPending = 60   // iOS keeps at most 64 pending notifications per app

    struct Snapshot {
        var habits: [Habit]
        var isDue: (Habit, Date) -> Bool
        var isCompletedToday: (Habit) -> Bool
        var streak: Int
        var constellationName: String
        var constellationPoints: Int
        var name: String
    }

    static func plan(_ s: Snapshot, now: Date = .now, calendar: Calendar = .current) -> [NotificationItem] {
        var items: [NotificationItem] = []
        let today = calendar.startOfDay(for: now)
        let soon = now.addingTimeInterval(60)
        let habits = s.habits.filter { !$0.isDemoData }

        func at(_ day: Date, _ hour: Int, _ minute: Int) -> Date? {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
        }

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayKey = DayKey.key(for: day)
            let due = habits.filter { habit in
                s.isDue(habit, day) && !(offset == 0 && s.isCompletedToday(habit))
            }
            guard !due.isEmpty else { continue }

            // 1. The user's own reminder times.
            for habit in due where habit.reminderEnabled {
                let time = calendar.dateComponents([.hour, .minute], from: habit.reminderTime)
                guard let fire = at(day, time.hour ?? 20, time.minute ?? 0), fire > soon else { continue }
                let text = NotificationCopy.reminder(habit: habit.name, star: s.constellationName,
                                                     points: s.constellationPoints, seed: seed(dayKey, habit.name))
                items.append(NotificationItem(id: "\(idPrefix)reminder.\(habit.id.uuidString).\(dayKey)",
                                              kind: .reminder, date: fire, title: text.title, body: text.body))
            }

            // 2. One gentle evening nudge for due habits without a reminder time.
            let quiet = due.filter { !$0.reminderEnabled }
            if !quiet.isEmpty, let fire = at(day, eveningTime.hour, eveningTime.minute), fire > soon {
                let text = NotificationCopy.evening(habits: quiet.map(\.name), star: s.constellationName,
                                                    name: s.name, seed: seed(dayKey, "evening"))
                items.append(NotificationItem(id: "\(idPrefix)evening.\(dayKey)", kind: .evening,
                                              date: fire, title: text.title, body: text.body))
            }

            // 3. Today only: keep the streak alive.
            if offset == 0, s.streak > 0,
               let fire = at(day, streakTime.hour, streakTime.minute), fire > soon {
                let text = NotificationCopy.streak(days: s.streak, remaining: due.count, seed: seed(dayKey, "streak"))
                items.append(NotificationItem(id: "\(idPrefix)streak.\(dayKey)", kind: .streak,
                                              date: fire, title: text.title, body: text.body))
            }
        }

        // 4. If the app isn't opened for a week, Nujaima says she misses you.
        if !habits.isEmpty,
           let day = calendar.date(byAdding: .day, value: missYouAfterDays, to: today),
           let fire = at(day, 19, 0) {
            let text = NotificationCopy.missYou(star: s.constellationName, name: s.name)
            items.append(NotificationItem(id: "\(idPrefix)missyou", kind: .missYou,
                                          date: fire, title: text.title, body: text.body))
        }

        return Array(items.sorted { $0.date < $1.date }.prefix(maxPending))
    }

    // Same text for the same day and habit (so rescheduling doesn't reshuffle it),
    // different from one day to the next.
    private static func seed(_ a: String, _ b: String) -> Int {
        (a + b).unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFF_FFFF }
    }
}

// MARK: - Copy (Nujaima's voice, for everyone)

enum NotificationCopy {
    struct Text { let title: String; let body: String }

    static func reminder(habit: String, star: String, points: Int, seed: Int) -> Text {
        let left = max(HabitProgress.pointsPerConstellation - points, 0)
        let bodies = [
            "حان وقت «\(habit)» ✨ إنجاز واحد ويضيء جزء جديد من «\(star)»",
            "نُجيمة تستناك! «\(habit)» يقرّبك ٥ نقاط من نجمتك 🌟",
            "خطوة صغيرة اليوم، نجمة أنور بكرة 💫 يلا «\(habit)»",
            "«\(habit)» وقتها الحين 🌙 نجمتك متحمسة تشوفك",
            left > 0 ? "باقي \(arabicNumber(left)) نقطة وتكتمل مجموعة «\(star)» 🌌 نبدأ «\(habit)» الحين؟"
                     : "نجوم «\(star)» تلمع بفضلك ✨ وقت «\(habit)»"
        ]
        let titles = ["نُجيمة تناديك ✨", "وقت عادتك 🌟", "نُجيمة هنا 💛"]
        return Text(title: titles[seed % titles.count], body: bodies[seed % bodies.count])
    }

    static func evening(habits: [String], star: String, name: String, seed: Int) -> Text {
        let who = name.isEmpty ? "" : " يا \(name)"
        let body: String
        if habits.count == 1 {
            let options = [
                "باقي «\(habits[0])» اليوم، وتضيء نجمتك ✨",
                "«\(habits[0])» تستناك الليلة 🌙 خلّ نجوم «\(star)» تلمع",
                "إنجاز واحد يفصلك عن نجمة جديدة 🌟 «\(habits[0])»"
            ]
            body = options[seed % options.count]
        } else {
            let options = [
                "باقي \(habitsCount(habits.count)) اليوم… كل وحدة تضوي سماك أكثر 💫",
                "السماء تستناك الليلة 🌌 كمّل \(habitsCount(habits.count)) وخلّ نجوم «\(star)» تلمع",
                "نُجيمة جهّزت النجوم ✨ باقي \(habitsCount(habits.count)) اليوم"
            ]
            body = options[seed % options.count]
        }
        let titles = ["نُجيمة تسأل عنك\(who) 🌙", "مساء النور\(who) ✨", "سماك تنتظرك 🌌"]
        return Text(title: titles[seed % titles.count], body: body)
    }

    static func streak(days: Int, remaining: Int, seed: Int) -> Text {
        let bodies = [
            "لا تخلّيه ينطفي! كمّل \(habitsCount(remaining)) قبل نهاية اليوم ✨",
            "نُجيمة حارسة على ستريكك 🛡️ باقي \(habitsCount(remaining)) بس",
            "\(arabicNumber(days)) أيام وأنت تضوي 🌟 خلّها \(arabicNumber(days + 1)) الليلة"
        ]
        return Text(title: "ستريكك \(arabicNumber(days)) 🔥", body: bodies[seed % bodies.count])
    }

    static func missYou(star: String, name: String) -> Text {
        let who = name.isEmpty ? "" : " يا \(name)"
        return Text(title: "اشتقنا لك\(who) 🥺",
                    body: "نُجيمة تنطرك في السماء… نجوم «\(star)» تستناك ترجع تضويها ✨")
    }

    // «عادة واحدة»، «عادتين»، «٣ عادات»، «١١ عادة»
    static func habitsCount(_ n: Int) -> String {
        switch n {
        case 1: return "عادة واحدة"
        case 2: return "عادتين"
        case 3...10: return "\(arabicNumber(n)) عادات"
        default: return "\(arabicNumber(n)) عادة"
        }
    }
}

// MARK: - Scheduling

enum NujaimaNotifications {
    // Replaces every pending Wahj notification with a fresh plan.
    static func reschedule(_ items: [NotificationItem]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let old = pending.map(\.identifier).filter { $0.hasPrefix(NotificationPlanner.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: old)
        guard !items.isEmpty, await isAllowed(center) else { return }

        for item in items {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.threadIdentifier = "wahj.nujaima"
            content.interruptionLevel = .active
            if let attachment = attachment(for: item) { content.attachments = [attachment] }

            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.date)
            let request = UNNotificationRequest(
                identifier: item.id, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix(NotificationPlanner.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Asks once (the first time there is something to remind about).
    private static func isAllowed(_ center: UNUserNotificationCenter) async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default: return false
        }
    }

    // Nujaima on a small night-sky card, saved as a file the notification can show.
    static func attachment(for item: NotificationItem) -> UNNotificationAttachment? {
        guard let star = UIImage(named: item.imageName) else { return nil }
        let size = CGSize(width: 300, height: 300)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let cg = context.cgContext
            let colors = [UIColor(red: 0.43, green: 0.25, blue: 0.54, alpha: 1).cgColor,
                          UIColor(red: 0.20, green: 0.13, blue: 0.25, alpha: 1).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: nil)!
            cg.drawRadialGradient(gradient, startCenter: CGPoint(x: 150, y: 140), startRadius: 0,
                                  endCenter: CGPoint(x: 150, y: 150), endRadius: 230, options: .drawsAfterEndLocation)
            // a few distant stars
            UIColor.white.withAlphaComponent(0.7).setFill()
            for (x, y, r) in [(40.0, 50.0, 2.5), (250, 40, 2), (265, 230, 2.5), (30, 245, 2), (150, 20, 1.5)] {
                cg.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            }
            star.draw(in: CGRect(x: 40, y: 40, width: 220, height: 220))
        }
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nujaima-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return try UNNotificationAttachment(identifier: "nujaima", url: url, options: nil)
        } catch {
            return nil
        }
    }
}
