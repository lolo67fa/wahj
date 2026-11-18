import Foundation

struct DailyDashboard: Identifiable, Equatable {
    let id: String
    let weekdaySymbol: String
    let dayNumber: String
    let greeting: String
    let dateText: String
    let streakDays: Int
    let goalPoints: Int
    var habits: [Habit]

    var completedPoints: Int {
        habits
            .filter(\.isDone)
            .reduce(0) { $0 + $1.points }
    }

    var completedHabitCount: Int {
        habits.filter(\.isDone).count
    }
}

struct ConstellationProgress: Equatable {
    static let pointsPerStar = 100
    static let starsPerConstellation = 7

    let totalPoints: Int

    var earnedStars: Int {
        totalPoints / Self.pointsPerStar
    }

    var pointsTowardNextStar: Int {
        totalPoints % Self.pointsPerStar
    }

    var currentStarNumber: Int {
        earnedStars + 1
    }

    var completedConstellations: Int {
        earnedStars / Self.starsPerConstellation
    }

    var litStarsInCurrentConstellation: Int {
        earnedStars % Self.starsPerConstellation
    }
}

enum SampleDashboardData {
    static let days: [DailyDashboard] = [
        DailyDashboard(
            id: "2026-11-14",
            weekdaySymbol: "س",
            dayNumber: "١٤",
            greeting: "صباح الخير، مها",
            dateText: "السبت، ١٤ نوفمبر",
            streakDays: 2,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات", isDone: true),
                Habit(id: "water", title: "شرب الماء"),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة")
            ]
        ),
        DailyDashboard(
            id: "2026-11-15",
            weekdaySymbol: "ح",
            dayNumber: "١٥",
            greeting: "صباح الخير، مها",
            dateText: "الأحد، ١٥ نوفمبر",
            streakDays: 3,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات"),
                Habit(id: "water", title: "شرب الماء", isDone: true),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة", isDone: true)
            ]
        ),
        DailyDashboard(
            id: "2026-11-16",
            weekdaySymbol: "ن",
            dayNumber: "١٦",
            greeting: "مساء الخير، مها",
            dateText: "الاثنين، ١٦ نوفمبر",
            streakDays: 4,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات", isDone: true),
                Habit(id: "water", title: "شرب الماء"),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة")
            ]
        ),
        DailyDashboard(
            id: "2026-11-17",
            weekdaySymbol: "ث",
            dayNumber: "١٧",
            greeting: "مساء الخير، مها",
            dateText: "الثلاثاء، ١٧ نوفمبر",
            streakDays: 5,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات", isDone: true),
                Habit(id: "water", title: "شرب الماء", isDone: true),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة")
            ]
        ),
        DailyDashboard(
            id: "2026-11-18",
            weekdaySymbol: "ر",
            dayNumber: "١٨",
            greeting: "مساء الخير، مها",
            dateText: "الأربعاء، ١٨ نوفمبر",
            streakDays: 6,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات", isDone: true),
                Habit(id: "water", title: "شرب الماء", isDone: true),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة", isDone: true)
            ]
        ),
        DailyDashboard(
            id: "2026-11-19",
            weekdaySymbol: "خ",
            dayNumber: "١٩",
            greeting: "صباح الخير، مها",
            dateText: "الخميس، ١٩ نوفمبر",
            streakDays: 7,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات"),
                Habit(id: "water", title: "شرب الماء"),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة")
            ]
        ),
        DailyDashboard(
            id: "2026-11-20",
            weekdaySymbol: "ج",
            dayNumber: "٢٠",
            greeting: "صباح الخير، مها",
            dateText: "الجمعة، ٢٠ نوفمبر",
            streakDays: 8,
            goalPoints: 15,
            habits: [
                Habit(id: "reading", title: "قراءة ١٠ صفحات"),
                Habit(id: "water", title: "شرب الماء", isDone: true),
                Habit(id: "walk", title: "مشي ٢٠ دقيقة")
            ]
        )
    ]
}
