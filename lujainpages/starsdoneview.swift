import SwiftUI

struct StarCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0          // entrance stage (0 → 5)
    @State private var isClosing = false // exit animation
    @State private var glow = false      // soft pulse on the main button

    var body: some View {
        VStack(spacing: 0) {

            //  Header will be deletteedd
            HStack(alignment: .top) {
                Circle()
                    .fill(Theme.card)
                    .frame(width: 44, height: 44)
                    .overlay(Text("م").foregroundStyle(Theme.cream))

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Text("مساء الخير، مها")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.white)

                    Text("الثلاثاء، ١٠ نوفمبر")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.pink.opacity(0.8))

                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                        Text("٤ أيام").font(.subheadline)
                    }
                    .foregroundStyle(Theme.cream)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.card)
                    .clipShape(Capsule())
                    .overlay { Capsule().stroke(Theme.border, lineWidth: 1) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 25)
            .padding(.bottom, 20)
            .opacity(isClosing ? 0 : 1)
            .animation(.easeOut(duration: 0.3), value: isClosing)

            // sheet
            VStack(alignment: .trailing, spacing: 14) {

                // X button
                HStack {
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.cream)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Theme.cream.opacity(0.7), lineWidth: 1))
                    }
                    .buttonStyle(CloseButtonStyle())
                    Spacer()
                }

                ProgressCard(
                    completedPoints: 5,
                    goalPoints: 15,
                    completedHabitCount: 1,
                    totalHabitCount: 3,
                    pointsTowardNextStar: 5,
                    currentStarNumber: 2,
                    litStarsInConstellation: 1,
                    completedConstellations: 0
                )
                    .scaleEffect(step >= 2 ? 1 : 0.85)
                    .opacity(step >= 2 ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: step)

                Text("اكتملت النجمة ·")
                    .font(.caption)
                    .foregroundStyle(Theme.cream.opacity(0.8))
                    .padding(.top, 6)
                    .reveal(step >= 3)

                Text("أضاءت أول نجمة!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.pink)
                    .reveal(step >= 3, scale: 0.8)

                Text("باقي ٦ نجوم وتكتمل الدب الأكبر")
                    .font(.footnote)
                    .foregroundStyle(Theme.cream.opacity(0.8))
                    .reveal(step >= 3)

                Button(action: close) {
                    Text("شوف نجمتك")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(red: 0.19, green: 0.13, blue: 0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().fill(Theme.pink))
                        .shadow(color: Theme.pink.opacity(glow ? 0.6 : 0.25),
                                radius: glow ? 22 : 12, y: 8)
                }
                .padding(.top, 16)
                .reveal(step >= 4, scale: 0.9, offset: 30)

                Button(action: close) {
                    Text("تم")
                        .font(.subheadline)
                        .foregroundStyle(Theme.cream.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .reveal(step >= 5)

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32,
                                       style: .continuous)
                    .fill(Theme.card)
                    .ignoresSafeArea(edges: .bottom)
            )
            // Sheet slides up on entrance, down on exit
            .offset(y: isClosing ? 700 : (step >= 1 ? 0 : 700))
            .animation(.spring(response: 0.55, dampingFraction: 0.85), value: step)
            .animation(.easeIn(duration: 0.35), value: isClosing)
        }
        .safeAreaInset(edge: .bottom) {
//            BottomTabBar() m
//                .environment(\.layoutDirection, .rightToLeft)
//                .padding(.horizontal, 20)
//                .padding(.bottom)
        }
        .background { StarryBackground() }
        .environment(\.layoutDirection, .leftToRight)
        .task { await runEntrance() }
    }

    // Animation

    private func runEntrance() async {
        let delays: [UInt64] = [150, 450, 450, 400, 300]   // ms before each step
        for (i, ms) in delays.enumerated() {
            try? await Task.sleep(nanoseconds: ms * 1_000_000)
            step = i + 1
        }
        // entrance finished → start the gentle glow on the button
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            glow = true
        }
    }

    private func close() {
        isClosing = true
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            dismiss()
        }
    }
}

// X button style
struct CloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? 90 : 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}


extension View {
    func reveal(_ visible: Bool, scale: CGFloat = 1, offset: CGFloat = 16) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : scale)
            .offset(y: visible ? 0 : offset)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: visible)
    }
}

#Preview {
    StarCompletionView()
}
