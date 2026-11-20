import SwiftUI

struct LamisView: View {
    @Environment(HabitStore.self) private var store
    @Binding var selectedTab: Int
    @State private var editingHabit: Habit?
    @State private var isAddingHabit = false

    // Today's habits: favorites (starred) first, then the rest;
    // inside each group, not-done habits come before done ones.
    private var todayHabits: [Habit] {
        let today = store.habits.filter { $0.isScheduledToday && !$0.isFinished }
        return favoritesFirst(today.filter { !$0.isDoneToday }) + favoritesFirst(today.filter(\.isDoneToday))
    }
    private var otherHabits: [Habit] {
        favoritesFirst(store.habits.filter { !$0.isScheduledToday && !$0.isFinished })
    }
    private var finishedHabits: [Habit] { favoritesFirst(store.habits.filter(\.isFinished)) }

    private func favoritesFirst(_ habits: [Habit]) -> [Habit] {
        habits.filter(\.isFavorite) + habits.filter { !$0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("عاداتي")
                        .font(.largeTitle).bold()
                        .foregroundStyle(AppTheme.text)
                    Spacer()

                    Button {
                        isAddingHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 48, height: 48)
                            .background(Theme.pink, in: Circle())
                            .shadow(color: Theme.pink.opacity(0.6), radius: 10)
                    }
                    .accessibilityLabel("أضف عادة")
                }

                if store.habits.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(todayHabits) { habit in
                                card(for: habit)
                            }

                            if !otherHabits.isEmpty {
                                sectionTitle("ليست اليوم")
                                ForEach(otherHabits) { habit in
                                    card(for: habit)
                                        .opacity(0.55)
                                }
                            }

                            if !finishedHabits.isEmpty {
                                sectionTitle("مكتملة")
                                ForEach(finishedHabits) { habit in
                                    card(for: habit)
                                }
                            }
                        }
                        .animation(.snappy, value: store.habits.map(\.todayCount))
                        // Starred habits slide to the top.
                        .animation(.snappy, value: store.habits.map(\.isFavorite))
                    }
                    .scrollIndicators(.hidden)
                }

                BottomTabBar(selected: $selectedTab)
            }
            .padding()
            .background { StarryBackground() }
            .navigationDestination(item: $editingHabit) { habit in
                AddHabitView(editing: habit)
            }
            .navigationDestination(isPresented: $isAddingHabit) {
                AddHabitView()
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.text.opacity(0.6))
            .padding(.top, 8)
    }

    private func card(for habit: Habit) -> some View {
        HabitCard(habit: habit,
                  onLog: { store.logOnce(habit) },
                  onToggleFavorite: { store.toggleFavorite(habit) })
            // Tap a card to edit it; long-press for more options.
            .contentShape(RoundedRectangle(cornerRadius: 24))
            .onTapGesture { editingHabit = habit }
            .accessibilityAction(named: "تعديل") { editingHabit = habit }
            .contextMenu {
                Button("تعديل", systemImage: "pencil") {
                    editingHabit = habit
                }
                if habit.todayCount > 0 {
                    Button("تراجع عن آخر مرة", systemImage: "arrow.uturn.backward") {
                        store.undoOnce(habit)
                    }
                }
                Button("حذف", systemImage: "trash", role: .destructive) {
                    store.delete(habit)
                }
            }
    }

    // Shown when there are no habits yet.
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image("app icon?")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .accessibilityHidden(true)
            Text("ابدأ أول عادة")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
            Text("كل نجمة تبدأ بخطوة صغيرة")
                .foregroundStyle(AppTheme.text.opacity(0.7))
            ActionButton(title: "أضف عادة", icon: "plus", isPrimary: true) {
                isAddingHabit = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            Spacer()
        }
    }
}

#Preview {
    LamisView(selectedTab: .constant(1))
        .environment(HabitStore.preview)
}
