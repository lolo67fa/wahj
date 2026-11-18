import SwiftUI

struct Habit: Identifiable, Equatable {
    let id: String
    var title: String
    var points: Int = 5
    var isDone: Bool = false
}

struct HabitsSection: View {
    @Binding var habits: [Habit]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("عاداتك اليوم")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            ForEach($habits) { $habit in
                HabitRow(habit: $habit)
            }
        }
        .padding(.horizontal, 20)
    }
}

struct HabitRow: View {
    @Binding var habit: Habit

    private let rowColor = Color(red: 0.25, green: 0.18, blue: 0.32)
    private let accent = Color(red: 0.91, green: 0.70, blue: 0.90)

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                habit.isDone.toggle()
            }
        } label: {
            HStack {
                Text(habit.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                PointsBadge(points: habit.points, isDone: habit.isDone)
            }
            .padding(.horizontal, 18)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(rowColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(accent)
                    .frame(width: 3, height: 40)
                    .padding(.trailing, 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct PointsBadge: View {
    let points: Int
    let isDone: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
            }

            Text("+\(points)")
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(Color(red: 0.55, green: 0.20, blue: 0.55))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(
                isDone
                ? Color(red: 0.98, green: 0.86, blue: 0.92)
                : Color(red: 0.97, green: 0.93, blue: 0.99)
            )
        )
    }
}
