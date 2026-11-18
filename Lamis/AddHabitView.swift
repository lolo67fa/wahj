import SwiftUI

// Add Habit screen: the user names a new habit, picks an icon and days,
// sets a reminder and a duration, then starts their journey.
struct AddHabitView: View {
    @State private var habitName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("أضف عادة")
                .font(.largeTitle).bold()
                .foregroundStyle(.white)

            Text("اسم العادة")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("قراءة ١٠ صفحات", text: $habitName)
                .padding(16)
                .foregroundStyle(.white)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
        .padding()
        .background { StarryBackground() }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    AddHabitView()
}
