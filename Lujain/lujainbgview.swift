import SwiftUI

struct HomeView: View {
    @Environment(HabitStore.self) private var store
    @Binding var selectedTab: Int

    // الاسم من صفحة «وش حاب نناديك؟» والنقاط من StarProgress
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("starTotalPoints") private var totalPoints = 0

    @State private var selectedDayID: String
    @State private var isShowingStarCompletion = false
    @State private var isShowingStars = false

    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
        _selectedDayID = State(initialValue: Self.dayID(for: Date()))
    }

    private static func dayID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Derived state

    // The current week (Saturday ... Friday), built from the shared habits.
    private var days: [DailyDashboard] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let todayIndex = Habit.dayIndex(of: today)
        guard let saturday = calendar.date(byAdding: .day, value: -todayIndex, to: today) else { return [] }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: saturday).map { dashboard(for: $0) }
        }
    }

    private func dashboard(for date: Date) -> DailyDashboard {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let dayIndex = Habit.dayIndex(of: date)

        let habits = store.habits
            .filter { $0.days.contains(dayIndex) && !$0.isFinished }
            .map { habit in
                DashboardHabit(
                    id: habit.id.uuidString,
                    title: habit.name,
                    points: StarProgress.pointsPerHabit,
                    isDone: isToday
                        ? habit.isDoneToday
                        : habit.lastCompletedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                )
            }

        let hour = calendar.component(.hour, from: .now)
        let greeting = hour < 12 ? "صباح الخير" : "مساء الخير"
        let dayLetters = ["س", "ح", "ن", "ث", "ر", "خ", "ج"]

        return DailyDashboard(
            id: Self.dayID(for: date),
            weekdaySymbol: dayLetters[dayIndex],
            dayNumber: arabicNumber(calendar.component(.day, from: date)),
            greeting: displayName.isEmpty ? greeting : "\(greeting)، \(displayName)",
            dateText: date.formatted(
                .dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ar"))
            ),
            streakDays: store.habits.map(\.streak).max() ?? 0,
            goalPoints: habits.count * StarProgress.pointsPerHabit,
            habits: habits
        )
    }

    private var selectedDay: DailyDashboard? {
        days.first { $0.id == selectedDayID }
    }

    // Only today's habits can be marked done from the home page.
    private func toggle(_ row: DashboardHabit) {
        guard selectedDayID == Self.dayID(for: Date()),
              let habit = store.habits.first(where: { $0.id.uuidString == row.id }) else { return }
        store.toggleDone(habit)
    }

    private var constellationProgress: ConstellationProgress {
        ConstellationProgress(totalPoints: totalPoints)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let selectedDay {
                    dashboard(for: selectedDay)
                } else {
                    ContentUnavailableView(
                        "لا توجد بيانات",
                        systemImage: "calendar"
                    )
                    .foregroundStyle(.white)
                }
            }
            .background { StarryBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingStars) {
                StarsView(progress: constellationProgress)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .onChange(of: constellationProgress.earnedStars) { oldValue, newValue in
            if newValue > oldValue {
                isShowingStarCompletion = true
            }
        }
        .fullScreenCover(isPresented: $isShowingStarCompletion) {
            StarCompletionView()
        }
    }

    private func dashboard(for day: DailyDashboard) -> some View {
        VStack(alignment: .trailing, spacing: 20) {
            DashboardHeader(
                greeting: day.greeting,
                dateText: day.dateText,
                streakDays: day.streakDays
            )

            Button {
                isShowingStars = true
            } label: {
                ProgressCard(
                    completedPoints: day.completedPoints,
                    goalPoints: day.goalPoints,
                    completedHabitCount: day.completedHabitCount,
                    totalHabitCount: day.habits.count,
                    pointsTowardNextStar: constellationProgress.pointsTowardNextStar,
                    currentStarNumber: constellationProgress.currentStarNumber,
                    litStarsInConstellation: constellationProgress.litStarsInCurrentConstellation,
                    completedConstellations: constellationProgress.completedConstellations
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            WeekDaysView(days: days, selectedDayID: $selectedDayID)
                .environment(\.layoutDirection, .rightToLeft)

            ScrollView {
                HabitsSection(habits: day.habits, onToggle: toggle)
                    .padding(.horizontal, -20)
                    .padding(.bottom, 24)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 20)
        .padding(.top, 25)
        .safeAreaInset(edge: .bottom) {
            BottomTabBar(selected: $selectedTab)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Header

struct DashboardHeader: View {
    let greeting: String
    let dateText: String
    let streakDays: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(greeting)
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.white)

            Text(dateText)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.pink.opacity(0.8))

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                Text("\(streakDays) أيام متتالية")
                    .font(.subheadline)
            }
            .foregroundStyle(Theme.cream)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Theme.card)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Theme.border, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .environment(\.layoutDirection, .leftToRight)
    }
}

#Preview {
    HomeView()
        .environment(HabitStore.preview)
}
