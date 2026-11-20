import SwiftUI

// One row on the home dashboard. Built from the shared HabitStore habit.
struct DashboardHabit: Identifiable, Equatable {
    let id: String
    var title: String
    var points: Int = 5
    var isDone: Bool = false
    // Only today's completion can change; past days are read-only, future days can't be done.
    var isEditable: Bool = true
    var isFuture: Bool = false
}

struct HabitsSection: View {
    let habits: [DashboardHabit]
    var note: String? = nil
    var onToggle: (DashboardHabit) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("عاداتك اليوم")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.text)
                .padding(.horizontal, 4)

            if let note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.text.opacity(0.6))
                    .padding(.horizontal, 4)
            }

            ForEach(habits) { habit in
                DashboardHabitRow(habit: habit) {
                    onToggle(habit)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct DashboardHabitRow: View {
    let habit: DashboardHabit
    var action: () -> Void

    private let rowColor = AppTheme.surface
    private let accent = AppTheme.accent

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                HabitCheckbox(isOn: habit.isDone, isEnabled: habit.isEditable)

                Text(habit.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.text.opacity(0.9))

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
                    .stroke(AppTheme.text.opacity(0.12), lineWidth: 1)
            )
            .overlay(alignment: .trailing) {
                Capsule()
                    .fill(accent)
                    .frame(width: 3, height: 40)
                    .padding(.trailing, 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!habit.isEditable)
        .opacity(habit.isFuture ? 0.55 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(habit.title)
        .accessibilityValue(habit.isDone ? "منجزة، +\(habit.points) نقاط" : "غير منجزة")
        .accessibilityAddTraits(.isToggle)
        .accessibilityHint(habit.isEditable ? "اضغط لتسجيل إنجاز اليوم أو إلغائه" : "يمكن تعديل إنجاز اليوم فقط")
    }
}

// مربع الإنجاز: يتعبّى بالوردي مع علامة صح عند إنجاز العادة.
struct HabitCheckbox: View {
    let isOn: Bool
    var isEnabled = true

    private let accent = AppTheme.accent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isOn ? accent : Color.clear)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accent.opacity(isEnabled || isOn ? 1 : 0.45), lineWidth: 2)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.bg)
            }
        }
        .frame(width: 28, height: 28)
        .frame(minWidth: 44, minHeight: 44)   // comfortable tap area
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
        .foregroundStyle(Color(hex: "8C338C"))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(
                isDone
                ? AppTheme.onSkyAccent
                : AppTheme.onSky
            )
        )
    }
}
