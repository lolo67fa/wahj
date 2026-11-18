import SwiftUI

// Missed Habit screen: shown when the user misses a day.
// It reassures them (their star is still alive) and offers two choices:
// use the monthly "streak saver" or start a brand new streak.
struct MissedHabitView: View {
    var habitName = ""
    var canUseSaver = true
    var onUseSaver: () -> Void = {}
    var onRestart: () -> Void = {}
    var onClose: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var rotation = 0.0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    onClose()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Theme.pink)
                        .frame(width: 44, height: 44)
                        .background(Theme.card, in: Circle())
                        .overlay(Circle().stroke(Theme.pink.opacity(0.6), lineWidth: 1))
                }
                .accessibilityLabel("إغلاق")
            }
            Spacer()

            ZStack {
                // glow (back layer)
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.yellow.opacity(0.3), .clear],
                        center: .center, startRadius: 0, endRadius: 170))

                // rings
                OrbitRings(rotation: rotation)
                    .frame(width: 300, height: 300)

                // star (front layer)
                Image("sad_star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230, height: 230)
            }
            .frame(width: 340, height: 340)
            .onAppear {
                withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                    rotation = -360
                }
            }

            VStack(spacing: 8) {
                Text("افاا فاتتك عادة")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                Text("ولا يهمك! نجمتك ما انطفت. لك مرة كل شهر ترجع الستريك")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                if !habitName.isEmpty {
                    Text(habitName)
                        .font(.headline)
                        .foregroundStyle(Theme.pink)
                }
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                ActionButton(title: "إستخدم فرصة الشهر", icon: "arrow.counterclockwise", isPrimary: true) {
                    onUseSaver()
                    dismiss()
                }
                .disabled(!canUseSaver)
                .opacity(canUseSaver ? 1 : 0.5)
                ActionButton(title: "إبدأ سلسلة جديدة", icon: nil, isPrimary: false) {
                    onRestart()
                    dismiss()
                }
            }
            .padding(.top, 16)

            Spacer()
        }
        .padding()
        .background { StarryBackground() }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct OrbitRings: View {
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

            Ellipse()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .frame(width: 340, height: 130)
                .rotationEffect(.degrees(-12 + rotation))

            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 6, height: 6)
                .offset(x: -160)
                .rotationEffect(.degrees(rotation))
        }
    }
}

// Reusable pill button (also needed on the Add Habit page: "ابدأ رحلتك")
struct ActionButton: View {
    var title: String
    var icon: String?
    var isPrimary: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(isPrimary ? Theme.bg : Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(isPrimary ? Theme.pink : Theme.card)
                    .shadow(color: isPrimary ? Color(hex: "4A1A5A") : .clear, radius: 0, y: 4)
            )
            .overlay(Capsule().stroke(Theme.border, lineWidth: isPrimary ? 0 : 1))
        }
    }
}

#Preview {
    MissedHabitView()
}
