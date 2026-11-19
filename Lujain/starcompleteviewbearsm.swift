import SwiftUI

struct StarCompletionPage: View {
    var onNext: () -> Void = {}

    @State private var litStars = 0                                   // how many stars are lit (0...7)
    @State private var lineProgress: [CGFloat] = Array(repeating: 0, count: 7)
    @State private var showTitle = false
    @State private var showButton = false
    @State private var twinkle = false
    @State private var orbitRotation = 0.0

    private let titleColor = Theme.starLit
    private let darkPurple = Theme.onAccent

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            //  Constellation
            ZStack {
                OrbitRings(rotation: orbitRotation)
                    .frame(width: 320, height: 320)

                ConstellationView(litStars: litStars,
                                  lineProgress: lineProgress,
                                  twinkle: twinkle)
                    .frame(width: 230, height: 180)
            }
            .frame(height: 340)

            //  Texts
            VStack(spacing: 10) {
                Text("اكتملت نجمتك!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(titleColor)

                Text("جمعت ١٠٠ نقطة... النجمة صارت لك")
                    .font(.footnote)
                    .foregroundStyle(Theme.cream.opacity(0.85))
            }
            .padding(.top, 50)
            .opacity(showTitle ? 1 : 0)
            .scaleEffect(showTitle ? 1 : 0.85)
            .offset(y: showTitle ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: showTitle)

            Spacer()
            Spacer()

            // Button
            Button(action: onNext) {
                Text("اختار نجمتك الجاية")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(darkPurple)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Capsule().fill(Theme.pink))
                    .shadow(color: Theme.pink.opacity(0.35), radius: 14, y: 8)
            }
            .buttonStyle(PressScaleStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 40)
            .animation(.spring(response: 0.55, dampingFraction: 0.8), value: showButton)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { StarryBackground().ignoresSafeArea() }
        .environment(\.layoutDirection, .leftToRight)
        .task { await runAnimation() }
    }

    //  Animation sequence
    private func runAnimation() async {
        try? await Task.sleep(nanoseconds: 400_000_000)

        // slow rotation of the orbit ring (runs forever)
        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        // first star
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { litStars = 1 }
        try? await Task.sleep(nanoseconds: 350_000_000)

        // draw each line, then light the next star
        for i in 0..<6 {
            withAnimation(.easeInOut(duration: 0.4)) { lineProgress[i] = 1 }
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { litStars = i + 2 }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        // close the bowl
        withAnimation(.easeInOut(duration: 0.4)) { lineProgress[6] = 1 }
        try? await Task.sleep(nanoseconds: 600_000_000)

        showTitle = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        showButton = true

        // gentle twinkle on the stars
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            twinkle = true
        }
    }
}

//  Constellation (Big Dipper)
struct ConstellationView: View {
    let litStars: Int
    let lineProgress: [CGFloat]
    let twinkle: Bool

    // star positions as fractions of the view's width/height
    private let points: [CGPoint] = [
        CGPoint(x: 0.07, y: 0.18),   // 0 handle tip
        CGPoint(x: 0.23, y: 0.10),   // 1
        CGPoint(x: 0.36, y: 0.23),   // 2
        CGPoint(x: 0.50, y: 0.43),   // 3 bowl corner
        CGPoint(x: 0.92, y: 0.47),   // 4
        CGPoint(x: 0.87, y: 0.91),   // 5
        CGPoint(x: 0.52, y: 0.83)    // 6
    ]

    // which star connects to which
    private let segments: [(Int, Int)] = [(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,3)]

    var body: some View {
        GeometryReader { geo in
            let pts = points.map { CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height) }

            ZStack {
                // Lines
                ForEach(0..<segments.count, id: \.self) { i in
                    let a = pts[segments[i].0]
                    let b = pts[segments[i].1]
                    let isHandle = i < 3

                    LineShape(from: a, to: b)
                        .trim(from: 0, to: lineProgress[i])
                        .stroke(
                            isHandle ? Color(red: 1, green: 0.93, blue: 0.75)
                                     : Color(red: 0.55, green: 0.40, blue: 0.75).opacity(0.75),
                            style: StrokeStyle(lineWidth: isHandle ? 3 : 7, lineCap: .round)
                        )
                        .shadow(color: (isHandle ? Color.yellow : Color.purple).opacity(0.5),
                                radius: isHandle ? 4 : 8)
                }

                // Stars
                ForEach(0..<pts.count, id: \.self) { i in
                    let lit = i < litStars
                    Image(systemName: "sparkle")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0.92, blue: 0.6))
                        .shadow(color: .yellow.opacity(0.9), radius: 8)
                        .shadow(color: .yellow.opacity(0.5), radius: 16)
                        .scaleEffect(lit ? (twinkle ? 1.12 : 0.95) : 0.01)
                        .opacity(lit ? 1 : 0)
                        .position(pts[i])
                }
            }
        }
    }
}

struct LineShape: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        p.addLine(to: to)
        return p
    }
}

// Decorative orbit ring
struct OrbitRings: View {
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.text.opacity(0.12), lineWidth: 1)

            Ellipse()
                .stroke(Theme.text.opacity(0.18), lineWidth: 1)
                .frame(width: 340, height: 130)
                .rotationEffect(.degrees(-12 + rotation))

            Circle()
                .fill(Theme.text.opacity(0.35))
                .frame(width: 6, height: 6)
                .offset(x: -160)
                .rotationEffect(.degrees(rotation))
        }
    }
}

//  Button press
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6),
                       value: configuration.isPressed)
    }
}

#Preview {
    StarCompletionPage()
}
