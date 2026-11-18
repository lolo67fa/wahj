import SwiftUI

struct ContentView: View {
    @State private var days = SampleDashboardData.days
    @State private var selectedDayID: String
    @State private var isShowingStarCompletion = false
    @State private var isShowingStars = false

    init() {
        let days = SampleDashboardData.days
        let todayID = Self.dayID(for: Date())

        _selectedDayID = State(
            initialValue: days.first { $0.id == todayID }?.id
                ?? days.first?.id
                ?? ""
        )
    }

    private static func dayID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Derived state

    private var selectedDayIndex: Int? {
        days.firstIndex { $0.id == selectedDayID }
    }

    private var selectedDay: DailyDashboard? {
        selectedDayIndex.map { days[$0] }
    }

    private var selectedHabits: Binding<[Habit]> {
        Binding(
            get: {
                guard let index = selectedDayIndex else { return [] }
                return days[index].habits
            },
            set: { newValue in
                guard let index = selectedDayIndex else { return }
                days[index].habits = newValue
            }
        )
    }

    private var constellationProgress: ConstellationProgress {
        let totalPoints = days
            .flatMap(\.habits)
            .filter(\.isDone)
            .reduce(0) { $0 + $1.points }

        return ConstellationProgress(totalPoints: totalPoints)
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
                HabitsSection(habits: selectedHabits)
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
            BottomTabBar()
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
    ContentView()
}
