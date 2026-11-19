import SwiftUI

struct LamisView: View {
    @Environment(HabitStore.self) private var store
    @Binding var selectedTab: Int
    @State private var editingHabit: Habit?
    @State private var isAddingHabit = false

    // Today's habits: not done first, then done.
    private var todayHabits: [Habit] {
        let today = store.habits.filter { $0.isScheduledToday && !$0.isFinished }
        return today.filter { !$0.isDoneToday } + today.filter(\.isDoneToday)
    }
    private var otherHabits: [Habit] { store.habits.filter { !$0.isScheduledToday && !$0.isFinished } }
    private var finishedHabits: [Habit] { store.habits.filter(\.isFinished) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("عاداتي")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        isAddingHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
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
            .foregroundStyle(.white.opacity(0.6))
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
                .foregroundStyle(.white)
            Text("كل نجمة تبدأ بخطوة صغيرة")
                .foregroundStyle(.white.opacity(0.7))
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
