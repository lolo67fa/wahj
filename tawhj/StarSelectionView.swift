import SwiftUI

enum StarProgress {
    static let names = [
        "الدب الأصغر", "الدب الأكبر", "ذات الكرسي",
        "الجبار", "العقرب", "التنين"
    ]

    static let pointsPerStar = 100

    static func awardPoints(_ amount: Int) {
        guard amount > 0 else { return }

        let defaults = UserDefaults.standard
        let current = min(
            max(defaults.integer(forKey: "starTotalPoints"), 0),
            600
        )

        defaults.set(
            current + min(amount, 600 - current),
            forKey: "starTotalPoints"
        )
    }
}

struct StarSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("starTotalPoints")
    private var totalPoints = 0

    @AppStorage("selectedStarIndex")
    private var selectedStar = -1
    
    @State private var showAddHabit = false

    // نربط هذا الإجراء بصفحة إضافة العادة عند تجهيزها.
    var onAddHabit: () -> Void = {}

    private let pink = Color(
        red: 242 / 255,
        green: 179 / 255,
        blue: 230 / 255
    )

    private var unlockedIndex: Int {
        min(max(totalPoints, 0) / 100, 5)
    }

    private var validSelection: Bool {
        (0..<6).contains(selectedStar)
            && selectedStar <= unlockedIndex
    }

    private var featuredIndex: Int {
        validSelection ? selectedStar : 0
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 20) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        card(featuredIndex, featured: true)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 14
                        ) {
                            ForEach(
                                (0..<6).filter { $0 != featuredIndex },
                                id: \.self
                            ) { index in
                                card(index, featured: false)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }

                Button {
                    showAddHabit = true
                } label: {
                    Text("أضف عاداتك")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(
                            Color(
                                red: 51 / 255,
                                green: 32 / 255,
                                blue: 63 / 255
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(pink, in: Capsule())
                        .shadow(
                            color: Color(
                                red: 89 / 255,
                                green: 18 / 255,
                                blue: 88 / 255
                            ),
                            radius: 0,
                            y: 5
                        )
                }
                .buttonStyle(.plain)
                .disabled(!validSelection)
                .padding(.horizontal, 10)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(isPresented: $showAddHabit) {
            AddHabitView()
        }        .onAppear {
            if !validSelection {
                selectedStar = 0
            }
        }
    }

    private var header: some View {
        HStack {
            Text("اختار نجمتك")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(red: 1, green: 0.957, blue: 0.992))

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(pink)
                    .frame(width: 44, height: 44)
                    .background(
                        Color(red: 0.294, green: 0.184, blue: 0.361),
                        in: Circle()
                    )
                    .overlay {
                        Circle().stroke(pink, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("رجوع")
        }
    }

    private func points(for index: Int) -> Int {
        min(max(totalPoints - index * 100, 0), 100)
    }

    private func card(
        _ index: Int,
        featured: Bool
    ) -> some View {
        let unlocked = index <= unlockedIndex
        let progress = points(for: index)
        let selected = selectedStar == index

        return Button {
            guard unlocked else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                selectedStar = index
            }
        } label: {
            ZStack {
                ConstellationCardBackground(seed: index)

                VStack(alignment: .leading, spacing: 8) {
                    ConstellationDrawing(
                        index: index,
                        progress: Double(progress) / 100,
                        locked: !unlocked
                    )
                    .frame(height: featured ? 140 : 88)
                    .padding(.horizontal, featured ? 24 : 4)

                    HStack(spacing: 6) {
                        Text(StarProgress.names[index])
                            .font(
                                .system(
                                    size: featured ? 20 : 15,
                                    weight: .bold
                                )
                            )

                        Spacer(minLength: 0)

                        if !unlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(pink)
                        }
                    }
                    .foregroundStyle(.white)

                    HStack {
                        Text("١٠٠ نقطة")
                            .font(.system(size: 11))
                            .foregroundStyle(pink)

                        Spacer()

                        if selected {
                            Text("مختارة")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(
                                    Color(
                                        red: 51 / 255,
                                        green: 32 / 255,
                                        blue: 63 / 255
                                    )
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(pink, in: Capsule())
                        } else if progress == 100 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(pink)
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: featured ? 230 : 164)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        selected ? pink : pink.opacity(0.12),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.3), radius: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(
            "\(StarProgress.names[index])، ١٠٠ نقطة، "
            + (unlocked ? "\(progress) من ١٠٠" : "مقفلة")
        )
    }
}

private struct ConstellationCardBackground: View {
    let seed: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(
                    red: 110 / 255,
                    green: 63 / 255,
                    blue: 138 / 255
                )

                Canvas { context, size in
                    // نقاط ثابتة حتى لا تتغير الخلفية عند الاختيار.
                    for i in 0..<36 {
                        let x = CGFloat(
                            (i * 73 + seed * 19 + 11) % 347
                        ) / 347 * size.width

                        let y = CGFloat(
                            (i * 47 + seed * 31 + 7) % 229
                        ) / 229 * size.height

                        let radius: CGFloat = i % 4 == 0 ? 0.9 : 0.55

                        context.fill(
                            Path(
                                ellipseIn: CGRect(
                                    x: x,
                                    y: y,
                                    width: radius * 2,
                                    height: radius * 2
                                )
                            ),
                            with: .color(
                                .white.opacity(i % 3 == 0 ? 0.75 : 0.35)
                            )
                        )
                    }

                    for inset: CGFloat in [0, 14] {
                        let rect = CGRect(
                            x: size.width * 0.55 + inset,
                            y: -size.width * 0.45 + inset,
                            width: size.width * 0.9,
                            height: size.width * 0.9
                        )

                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(
                                Color(
                                    red: 78 / 255,
                                    green: 43 / 255,
                                    blue: 96 / 255
                                ).opacity(0.4)
                            ),
                            lineWidth: 1
                        )
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }
}

private struct ConstellationDrawing: View {
    let index: Int
    let progress: Double
    let locked: Bool

    private let gold = Color(
        red: 1,
        green: 235 / 255,
        blue: 166 / 255
    )

    // نقاط الرسم بنسب ثابتة، وليست أشكال نجوم خماسية.
    private var points: [CGPoint] {
        let coordinates: [(CGFloat, CGFloat)]

        switch index {
        case 0: // الدب الأصغر، والمقبض ينتهي بالنجم القطبي
            coordinates = [
                (0.10, 0.47), (0.23, 0.70),
                (0.42, 0.45), (0.29, 0.24),
                (0.60, 0.25), (0.78, 0.34),
                (0.94, 0.48)
            ]

        case 1: // الدب الأكبر كما في فيقما
            coordinates = [
                (0.10, 0.22), (0.24, 0.10),
                (0.35, 0.23), (0.47, 0.43),
                (0.81, 0.47), (0.76, 0.88),
                (0.49, 0.81)
            ]

        case 2: // ذات الكرسي
            coordinates = [
                (0.12, 0.15), (0.29, 0.78),
                (0.50, 0.37), (0.70, 0.91),
                (0.88, 0.20)
            ]

        case 3: // الجبار: الكتفان والحزام والقدمان
            coordinates = [
                (0.30, 0.10), (0.70, 0.14),
                (0.39, 0.48), (0.50, 0.51),
                (0.61, 0.54), (0.24, 0.91),
                (0.76, 0.91)
            ]

        case 4: // العقرب: جسم ممتد وذيل معقوف
            coordinates = [
                (0.18, 0.10), (0.29, 0.25),
                (0.34, 0.43), (0.44, 0.63),
                (0.59, 0.80), (0.76, 0.87),
                (0.88, 0.73), (0.84, 0.57),
                (0.72, 0.59)
            ]

        default: // التنين
            coordinates = [
                (0.79, 0.11), (0.94, 0.15),
                (0.90, 0.34), (0.76, 0.32),
                (0.62, 0.43), (0.48, 0.27),
                (0.30, 0.29), (0.16, 0.45),
                (0.23, 0.66), (0.43, 0.82),
                (0.65, 0.86)
            ]
        }

        return coordinates.map { CGPoint(x: $0.0, y: $0.1) }
    }

    private var edges: [(Int, Int)] {
        switch index {
        case 0:
            return [
                (0, 1), (1, 2), (2, 3), (3, 0),
                (2, 4), (4, 5), (5, 6)
            ]

        case 1:
            return [
                (0, 1), (1, 2), (2, 3),
                (3, 4), (4, 5), (5, 6), (6, 3)
            ]

        case 3:
            return [
                (0, 1), (0, 2), (1, 4),
                (2, 3), (3, 4), (2, 5), (4, 6)
            ]

        case 5:
            return [
                (0, 1), (1, 2), (2, 3), (3, 0),
                (3, 4), (4, 5), (5, 6), (6, 7),
                (7, 8), (8, 9), (9, 10)
            ]

        default:
            return (0..<(points.count - 1)).map { ($0, $0 + 1) }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let positions = points.map {
                CGPoint(
                    x: $0.x * geometry.size.width,
                    y: $0.y * geometry.size.height
                )
            }

            let litCount = min(
                points.count,
                Int(progress * Double(points.count))
            )

            ZStack {
                ForEach(edges.indices, id: \.self) { i in
                    let edge = edges[i]
                    let lit = !locked
                        && edge.0 < litCount
                        && edge.1 < litCount

                    Path { path in
                        path.move(to: positions[edge.0])
                        path.addLine(to: positions[edge.1])
                    }
                    .stroke(
                        lit ? gold : Color.white.opacity(0.28),
                        style: StrokeStyle(
                            lineWidth: lit ? 3 : 1.2,
                            lineCap: .round,
                            dash: lit ? [] : [2, 4]
                        )
                    )
                    .shadow(
                        color: lit ? gold.opacity(0.8) : .clear,
                        radius: 5
                    )
                }

                ForEach(positions.indices, id: \.self) { i in
                    let lit = !locked && i < litCount

                    ZStack {
                        if lit {
                            Circle()
                                .fill(gold.opacity(0.28))
                                .frame(width: 26, height: 26)
                                .blur(radius: 4)

                            Image(systemName: "sparkle")
                                .font(.system(size: 19))
                                .foregroundStyle(gold)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(locked ? 0.5 : 0.8))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .position(positions[i])
                }

                if locked {
                    Image(systemName: "lock")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            Color(red: 242 / 255, green: 179 / 255, blue: 230 / 255)
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            Color(
                                red: 110 / 255,
                                green: 63 / 255,
                                blue: 138 / 255
                            ),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.65), lineWidth: 1)
                        }
                }
            }
        }
        // تثبيت اتجاه الرسومات حتى لا تنعكس مع العربية.
        .environment(\.layoutDirection, .leftToRight)
        .animation(.easeInOut(duration: 0.8), value: progress)
        .accessibilityHidden(true)
    }
}

#Preview {
    StarSelectionView()
}
