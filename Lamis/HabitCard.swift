import SwiftUI

// One habit: a ring button on the right that fills with each tap
// (the icon turns pink when today's goal is reached), and a favorite star on the left.
struct HabitCard: View {
    var habit: Habit
    var onLog: () -> Void
    var onToggleFavorite: () -> Void

    private var isDone: Bool { habit.isDoneToday || habit.isFinished }
    private var ringProgress: Double { habit.isFinished ? 1 : habit.todayProgress }

    var body: some View {
        HStack(spacing: 14) {
            ringButton

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .strikethrough(habit.isDoneToday, color: Theme.pink)

                HStack(spacing: 10) {
                    if habit.isFinished {
                        Text("اكتملت الرحلة")
                    } else {
                        if habit.streak > 0 {
                            Label("\(arabicNumber(habit.streak)) أيام", systemImage: "flame.fill")
                                .labelStyle(StreakLabelStyle())
                        }
                        if habit.dailyGoal > 1 {
                            Text("\(arabicNumber(habit.todayCount)) من \(arabicNumber(habit.dailyGoal))")
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Favorite star, on the left like the original design.
            Button(action: onToggleFavorite) {
                Image(systemName: habit.isFavorite ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(habit.isFavorite ? Color.yellow : Theme.pink)
            }
            .accessibilityLabel(habit.isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة")
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isDone ? Theme.pink.opacity(0.7) : Theme.border, lineWidth: 1)
        )
    }

    // Each tap adds one; when the ring is full the icon turns pink.
    // Taps are ignored (not passed to the card) when the habit can't be logged.
    private var ringButton: some View {
        Button {
            if habit.canLogToday { onLog() }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Theme.pink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: habit.icon)
                    .font(.title3)
                    .foregroundStyle(isDone ? Theme.pink : Color.white)
            }
            .frame(width: 58, height: 58)
            .animation(.snappy, value: habit.todayCount)
        }
        .sensoryFeedback(.increase, trigger: habit.todayCount)
        .accessibilityLabel(habit.name)
        .accessibilityValue(isDone ? "تم" : "\(arabicNumber(habit.todayCount)) من \(arabicNumber(habit.dailyGoal))")
    }
}

// Pink flame icon next to the streak number.
struct StreakLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon.foregroundStyle(Theme.pink)
            configuration.title
        }
    }
}
