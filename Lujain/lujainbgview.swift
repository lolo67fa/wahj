import SwiftUI

struct HomeView: View {
    @Environment(HabitStore.self) private var store
    @Binding var selectedTab: Int

    // الاسم من صفحة «وش حاب نناديك؟» والمجموعة من صفحة «اختار نجمتك»
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("selectedStarIndex") private var selectedStar = 0

    @State private var selectedDayID: String
    @State private var isShowingStars = false

    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
        _selectedDayID = State(initialValue: DayKey.key(for: .now))
    }

    // MARK: - Derived state

    // The current week (Saturday ... Friday) around the real today, from the shared habits.
    private var days: [DailyDashboard] {
        let calendar = Calendar.current
        let today = store.today
        let todayIndex = Habit.dayIndex(of: today)
        guard let saturday = calendar.date(byAdding: .day, value: -todayIndex, to: today) else { return [] }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: saturday).map { dashboard(for: $0) }
        }
    }

    private func dashboard(for date: Date) -> DailyDashboard {
        let calendar = Calendar.current
        let dayIndex = Habit.dayIndex(of: date)
        let editable = store.canEditCompletion(on: date)
        let isFuture = calendar.startOfDay(for: date) > store.today

        // Habits due that day (its weekdays, after it started, journey not finished before it).
        let habits = store.habits
            .filter { !$0.isDemoData && store.isDue($0, on: date) }
            .map { habit in
                DashboardHabit(
                    id: habit.id.uuidString,
                    title: habit.name,
                    points: StarProgress.pointsPerHabit,
                    isDone: store.isCompleted(habit, on: date),
                    isEditable: editable,
                    isFuture: isFuture
                )
            }

        let hour = calendar.component(.hour, from: .now)
        let greeting = hour < 12 ? "صباح الخير" : "مساء الخير"
        let dayLetters = ["س", "ح", "ن", "ث", "ر", "خ", "ج"]

        return DailyDashboard(
            id: DayKey.key(for: date),
            weekdaySymbol: dayLetters[dayIndex],
            dayNumber: arabicNumber(calendar.component(.day, from: date)),
            greeting: displayName.isEmpty ? greeting : "\(greeting)، \(displayName)",
            dateText: date.formatted(
                .dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "ar"))
            ),
            // ستريك التطبيق من سجل الإنجازات وبالتاريخ الحقيقي، لا اليوم المعروض.
            streakDays: store.appStreak,
            goalPoints: habits.count * StarProgress.pointsPerHabit,
            habits: habits
        )
    }

    private var selectedDay: DailyDashboard? {
        days.first { $0.id == selectedDayID }
    }

    private var isTodaySelected: Bool { selectedDayID == DayKey.key(for: store.today) }

    // The chosen constellation (from «اختار نجمتك»).
    private var constellationIndex: Int {
        min(max(selectedStar, 0), HabitProgress.constellationCount - 1)
    }

    // Only today's completion can be changed from the home page.
    private func toggle(_ row: DashboardHabit) {
        guard row.isEditable,
              let habit = store.habits.first(where: { $0.id.uuidString == row.id }) else { return }
        store.toggleDone(habit)
    }

    private var constellationProgress: ConstellationProgress {
        ConstellationProgress(totalPoints: store.constellations.total)
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
                    .foregroundStyle(AppTheme.text)
                }
            }
            .background { StarryBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isShowingStars) {
                StarsView(progress: constellationProgress)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        // If the app stays open past midnight, move the selection to the new day.
        .onChange(of: store.today) { oldDay, newDay in
            if selectedDayID == DayKey.key(for: oldDay) {
                selectedDayID = DayKey.key(for: newDay)
            }
        }
    }

    private func dashboard(for day: DailyDashboard) -> some View {
        VStack(alignment: .trailing, spacing: 20) {
            DashboardHeader(
                greeting: day.greeting,
                dateText: day.dateText,
                streakDays: day.streakDays
            )

            ScrollView {
                VStack(alignment: .trailing, spacing: 20) {
                    Button {
                        isShowingStars = true
                    } label: {
                        HomeConstellationCard(
                            index: constellationIndex,
                            points: store.constellationPoints(constellationIndex),
                            nextUnlocked: store.isConstellationUnlocked(constellationIndex + 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    WeekDaysView(days: days, selectedDayID: $selectedDayID)
                        .environment(\.layoutDirection, .rightToLeft)

                    HabitsSection(
                        habits: day.habits,
                        note: dayNote(for: day),
                        onToggle: toggle
                    )
                    .padding(.horizontal, -20)
                    .padding(.bottom, 24)
                    .environment(\.layoutDirection, .rightToLeft)
                }
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

    private func dayNote(for day: DailyDashboard) -> String? {
        if day.habits.isEmpty { return "ما فيه عادات مستحقة في هذا اليوم" }
        if isTodaySelected { return nil }
        return day.habits.first?.isFuture == true
            ? "ما تقدر تنجز عادات يوم ما جاء"
            : "الأيام السابقة للعرض فقط"
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
                .foregroundStyle(AppTheme.text)

            Text(dateText)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(Theme.pink.opacity(0.8))

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                Text("\(arabicNumber(streakDays)) أيام متتالية")
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
