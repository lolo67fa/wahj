//
//  HabitIntroView.swift
//  Wahj
//
//  Created by ghala alshreef on 07/06/1448 AH.
//

import SwiftUI

struct HabitIntroView: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var litStars = 0
   
    @State private var showStarSelection = false

    private let pink = AppTheme.accent

    private let secondary = AppTheme.textSecondary

    // أماكن النجوم كنسب من مساحة الرسم
    private let points: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.23),
        CGPoint(x: 0.27, y: 0.16),
        CGPoint(x: 0.40, y: 0.27),
        CGPoint(x: 0.51, y: 0.40),
        CGPoint(x: 0.85, y: 0.44),
        CGPoint(x: 0.80, y: 0.76),
        CGPoint(x: 0.54, y: 0.71)
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 34) {
                        constellation
                            .frame(height: 285)
                            .padding(.top, 24)

                        HStack(spacing: 8) {
                            infoCard(
                                "سويت عادة",
                                subtitle: "يكتمل جزء من نجمتك"
                            )

                            infoCard(
                                "أنجزت عادة",
                                subtitle: "تحصل على ٥ نقاط"
                            )

                            infoCard(
                                "١٠٠ نقطة",
                                subtitle: "تكتمل نجمتك"
                            )
                        }

                        VStack(spacing: 12) {
                            Text("كل عادة تقرّبك")
                                .font(.title.bold())
                                .foregroundStyle(
                                    AppTheme.text
                                )

                            Text("من توسيع مدارك، ابدأ أنجز من اليوم")
                                .font(.subheadline)
                                .foregroundStyle(secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 38)
                    }
                    .padding(.bottom, 24)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(pink.opacity(0.25))
                        .frame(width: 8, height: 8)

                    Capsule()
                        .fill(pink)
                        .frame(width: 22, height: 8)
                }
                .padding(.vertical, 30)

                Button {
                    showStarSelection = true
                } label: {
                    Text("التالي")
                        .font(.headline)
                        .foregroundStyle(
                            AppTheme.background
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(pink, in: Capsule())
                        // الظل تحت الزر فقط، مو على النص
                        .compositingGroup()
                        .shadow(
                            color: AppTheme.accentShadow,
                            radius: 0,
                            y: 5
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 55)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .fullScreenCover(isPresented: $showStarSelection) {
            StarSelectionView()
        }
        .task(id: reduceMotion) {
            litStars = 0

            if reduceMotion {
                litStars = points.count
                return
            }

            // كل نجمة تنور بعد اللي قبلها وتبقى مضيئة
            for count in 1...points.count {
                do {
                    try await Task.sleep(
                        nanoseconds: 600_000_000
                    )
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.7)) {
                    litStars = count
                }
            }
        }
        .fullScreenCover(isPresented: $showStarSelection) {
            StarSelectionView()
        }
    }

    private var constellation: some View {
        GeometryReader { geometry in
            ZStack {
                // المسار الخافت للمجموعة كاملة
                constellationPath(in: geometry.size)
                    .stroke(
                        secondary.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            dash: [3, 5]
                        )
                    )

                // الخطوط تضيء مع النجوم
                ForEach(0..<(points.count - 1), id: \.self) {
                    index in

                    Path { path in
                        path.move(
                            to: position(index, in: geometry.size)
                        )
                        path.addLine(
                            to: position(index + 1, in: geometry.size)
                        )
                    }
                    .stroke(
                        Color(red: 1, green: 0.88, blue: 0.57),
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .shadow(color: .yellow, radius: 5)
                    .opacity(litStars > index + 1 ? 1 : 0)
                }

                ForEach(points.indices, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(secondary.opacity(0.7))
                            .frame(width: 5, height: 5)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.yellow.opacity(0.55),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 22
                                )
                            )
                            .frame(width: 44, height: 44)
                            .opacity(litStars > index ? 1 : 0)

                        GlowStarShape()
                            .fill(
                                Color(
                                    red: 1,
                                    green: 0.91,
                                    blue: 0.65
                                )
                            )
                            .frame(width: 23, height: 28)
                            .shadow(color: .yellow, radius: 8)
                            .scaleEffect(litStars > index ? 1 : 0.3)
                            .opacity(litStars > index ? 1 : 0)
                    }
                    .position(position(index, in: geometry.size))
                }
            }
        }
        // الرسم يحافظ على اتجاهه داخل الواجهة العربية
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("مجموعة نجمية تضيء تدريجيًا")
    }

    private func position(
        _ index: Int,
        in size: CGSize
    ) -> CGPoint {
        CGPoint(
            x: points[index].x * size.width,
            y: points[index].y * size.height
        )
    }

    private func constellationPath(in size: CGSize) -> Path {
        Path { path in
            path.move(to: position(0, in: size))

            for index in 1..<points.count {
                path.addLine(to: position(index, in: size))
            }

            // إغلاق مربع المجموعة النجمية
            path.addLine(to: position(3, in: size))
        }
    }

    private func infoCard(
        _ title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.bold())

            Text(subtitle)
                .font(.system(size: 10))
        }
        .foregroundStyle(secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 72)
        .padding(.horizontal, 4)
        .background(
            AppTheme.surface,
            in: RoundedRectangle(cornerRadius: 17)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(secondary.opacity(0.2), lineWidth: 1)
        }
    }
}

// نجمة بأربع أطراف للرسم المضيء
private struct GlowStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY

        return Path { path in
            path.move(to: CGPoint(x: cx, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: cy),
                control: CGPoint(x: cx + 3, y: cy - 3)
            )
            path.addQuadCurve(
                to: CGPoint(x: cx, y: rect.maxY),
                control: CGPoint(x: cx + 3, y: cy + 3)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: cy),
                control: CGPoint(x: cx - 3, y: cy + 3)
            )
            path.addQuadCurve(
                to: CGPoint(x: cx, y: rect.minY),
                control: CGPoint(x: cx - 3, y: cy - 3)
            )
            path.closeSubpath()
        }
    }
}

#Preview {
    HabitIntroView()
}
