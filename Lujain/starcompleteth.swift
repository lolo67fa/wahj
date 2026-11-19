import SwiftUI

//  Data for one constellation
struct ConstellationSpec {
    let points: [CGPoint]            // star positions (0...1 of the size)
    let segments: [(Int, Int)]       // which star connects to which
    var softFrom: Int = .max         // segments from this index on use the thick glow style
    let size: CGSize                 // size on screen
}

//The page
struct ConstellationCompletionPage: View {
    let spec: ConstellationSpec
    var onNext: () -> Void = {}

    @State private var lit: Set<Int> = []
    @State private var lineProgress: [CGFloat] = []
    @State private var showTitle = false
    @State private var showButton = false
    @State private var twinkle = false
    @State private var orbitRotation = 0.0

    private let titleColor = Theme.starLit
    private let darkPurple = Theme.onAccent

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                OrbitRings(rotation: orbitRotation)
                    .frame(width: 320, height: 320)

                ConstellationCanvas(spec: spec,
                                    lit: lit,
                                    lineProgress: lineProgress,
                                    twinkle: twinkle)
                    .frame(width: spec.size.width, height: spec.size.height)
            }
            .frame(height: 340)

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

    // Animation sequence
    private func runAnimation() async {
        lineProgress = Array(repeating: 0, count: spec.segments.count)
        try? await Task.sleep(nanoseconds: 400_000_000)

        withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        // first star
        if let first = spec.segments.first?.0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { lit.insert(first) }
        }
        try? await Task.sleep(nanoseconds: 350_000_000)

        // draw each line, then light the star at its end
        for (i, seg) in spec.segments.enumerated() {
            withAnimation(.easeInOut(duration: 0.4)) { lineProgress[i] = 1 }
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                lit.insert(seg.0)
                lit.insert(seg.1)
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        // any star not connected by a line (like the center of الثريا)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            for i in spec.points.indices { lit.insert(i) }
        }
        try? await Task.sleep(nanoseconds: 600_000_000)

        showTitle = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        showButton = true

        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            twinkle = true
        }
    }
}

//  Draws lines + stars
struct ConstellationCanvas: View {
    let spec: ConstellationSpec
    let lit: Set<Int>
    let lineProgress: [CGFloat]
    let twinkle: Bool

    var body: some View {
        GeometryReader { geo in
            let pts = spec.points.map {
                CGPoint(x: $0.x * geo.size.width, y: $0.y * geo.size.height)
            }

            ZStack {
                ForEach(0..<spec.segments.count, id: \.self) { i in
                    let a = pts[spec.segments[i].0]
                    let b = pts[spec.segments[i].1]
                    let soft = i >= spec.softFrom
                    let progress = i < lineProgress.count ? lineProgress[i] : 0

                    LineShape(from: a, to: b)
                        .trim(from: 0, to: progress)
                        .stroke(
                            soft ? Color(red: 0.55, green: 0.40, blue: 0.75).opacity(0.75)
                                 : Color(red: 1, green: 0.93, blue: 0.75),
                            style: StrokeStyle(lineWidth: soft ? 7 : 3, lineCap: .round)
                        )
                        .shadow(color: (soft ? Color.purple : Color.yellow).opacity(0.5),
                                radius: soft ? 8 : 4)
                }

                ForEach(0..<pts.count, id: \.self) { i in
                    let isLit = lit.contains(i)
                    Image(systemName: "sparkle")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(red: 1, green: 0.92, blue: 0.6))
                        .shadow(color: .yellow.opacity(0.9), radius: 8)
                        .shadow(color: .yellow.opacity(0.5), radius: 16)
                        .scaleEffect(isLit ? (twinkle ? 1.12 : 0.95) : 0.01)
                        .opacity(isLit ? 1 : 0)
                        .position(pts[i])
                }
            }
        }
    }
}
