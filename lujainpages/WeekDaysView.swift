import SwiftUI

struct WeekDaysView: View {
    let days: [DailyDashboard]
    @Binding var selectedDayID: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days) { day in
                Button {
                    selectedDayID = day.id
                } label: {
                    VStack(spacing: 6) {
                        Text(day.weekdaySymbol)
                            .font(.system(size: 14, weight: .medium))

                        Text(day.dayNumber)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(
                        selectedDayID == day.id
                        ? Theme.cream
                        : Theme.pink
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 65)
                    .background(Theme.card.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                selectedDayID == day.id
                                ? Theme.cream
                                : Theme.border,
                                lineWidth: selectedDayID == day.id ? 2 : 1
                            )
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(day.dateText)")
            }
        }
    }
}
