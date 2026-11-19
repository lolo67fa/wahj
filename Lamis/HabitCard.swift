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

            VStack(alignment: .leading, spacing: 8) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                    .strikethrough(habit.isDoneToday, color: Theme.pink)

                // Today: streak and today's count (e.g. water 7 of 15).
                if !habit.isFinished && (habit.streak > 0 || habit.dailyGoal > 1) {
                    HStack(spacing: 10) {
                        if habit.streak > 0 {
                            Label("\(arabicNumber(habit.streak)) أيام", systemImage: "flame.fill")
                                .labelStyle(StreakLabelStyle())
                        }
                        if habit.dailyGoal > 1 {
                            Text("\(arabicNumber(habit.todayCount)) من \(arabicNumber(habit.dailyGoal)) اليوم")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.text.opacity(0.7))
                }

                journeyRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Favorite star, on the left like the original design.
            Button(action: onToggleFavorite) {
                Image(systemName: habit.isFavorite ? "star.fill" : "star")
                    .font(.title)
                    .foregroundStyle(habit.isFavorite ? AppTheme.gold : Theme.pink)
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

    // The whole journey: a thin bar plus "5 of 14 days" (or "journey complete").
    private var journeyRow: some View {
        let progress = Double(habit.completedDays) / Double(max(habit.durationDays, 1))

        return HStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.text.opacity(0.12))
                    Capsule()
                        .fill(Theme.pink)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
            .animation(.snappy, value: habit.completedDays)

            Text(habit.isFinished
                 ? "اكتملت الرحلة"
                 : "\(arabicNumber(habit.completedDays)) من \(arabicNumber(habit.durationDays)) يوم")
                .font(.caption2)
                .foregroundStyle(AppTheme.text.opacity(0.6))
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("الرحلة")
        .accessibilityValue(habit.isFinished
            ? "اكتملت"
            : "\(arabicNumber(habit.completedDays)) من \(arabicNumber(habit.durationDays)) يوم")
    }

    // Each tap adds one; when the ring is full the icon turns pink.
    // Taps are ignored (not passed to the card) when the habit can't be logged.
    private var ringButton: some View {
        Button {
            if habit.canLogToday { onLog() }
        } label: {
            ZStack {
                Circle()
                    .stroke(AppTheme.text.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Theme.pink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: habit.icon)
                    .font(.title3)
                    .foregroundStyle(isDone ? Theme.pink : AppTheme.text)
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
