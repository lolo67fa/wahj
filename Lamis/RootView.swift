import SwiftUI

// The app's main screen: switches pages from the bottom tab bar,
// shows the "missed habit" page when a day was missed,
// and congratulates the user when a habit's journey is complete.
struct RootView: View {
    @State private var store = HabitStore()
    @State private var selectedTab = 1
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch selectedTab {
            case 1:
                LamisView(selectedTab: $selectedTab)
            case 0:
                ComingSoonView(title: "الرئيسية", selectedTab: $selectedTab)
            case 2:
                ComingSoonView(title: "نجمتي", selectedTab: $selectedTab)
            default:
                ComingSoonView(title: "أصدقائي", selectedTab: $selectedTab)
            }
        }
        .environment(store)
        // After one missed page closes, show the next missed habit (if any).
        .fullScreenCover(item: $store.missedHabit, onDismiss: { store.showNextMissed() }) { habit in
            MissedHabitView(
                habitName: habit.name,
                canUseSaver: store.canUseSaver,
                onUseSaver: { store.useSaver(habit) },
                onRestart: { store.restart(habit) },
                onClose: { store.skipMissed(habit) }
            )
        }
        .alert("مبروك!", isPresented: Binding(
            get: { store.justFinished != nil },
            set: { if !$0 { store.justFinished = nil } }
        ), presenting: store.justFinished) { _ in
            Button("شكراً") { }
        } message: { habit in
            Text("أكملت رحلة \"\(habit.name)\" — \(arabicNumber(habit.durationDays)) اليوم!")
        }
        // Check for a new day / missed days whenever the app comes back to the front.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.checkForNewDay() }
        }
        // If the app stays open past midnight, start the new day automatically.
        .task {
            while !Task.isCancelled {
                let calendar = Calendar.current
                guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) else { break }
                try? await Task.sleep(for: .seconds(midnight.timeIntervalSinceNow + 1))
                store.checkForNewDay()
            }
        }
    }
}

// Placeholder for tabs that teammates are building.
struct ComingSoonView: View {
    var title: String
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                Spacer()
            }
            Spacer()
            Text("قريباً")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            BottomTabBar(selected: $selectedTab)
        }
        .padding()
        .background { StarryBackground() }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    RootView()
}
