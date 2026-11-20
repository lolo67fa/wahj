//
//  SpaceBackground.swift
//  tawhj
//
//  Created by ghala alshreef on 05/06/1448 AH.
//

import SwiftUI

// الخلفية المشتركة لكل الصفحات
struct SpaceBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let sx = geometry.size.width / 402
            let sy = geometry.size.height / 874

            ZStack {
                // نفس البنفسجي المعتمد (داكن) ولون فيقما الفاتح، حسب المظهر
                AppTheme.background

                Canvas { context, _ in
                    let color = AppTheme.orbit

                    // المدارات الكبيرة عند أطراف الشاشة
                    let circles: [CGRect] = [
                        CGRect(x: 174, y: -185, width: 370, height: 370),
                        CGRect(x: 188, y: -171, width: 342, height: 342),
                        CGRect(x: -180, y: 635, width: 380, height: 380),
                        CGRect(x: -163, y: 652, width: 346, height: 346)
                    ]

                    for circle in circles {
                        let rect = CGRect(
                            x: circle.minX * sx,
                            y: circle.minY * sy,
                            width: circle.width * sx,
                            height: circle.height * sy
                        )

                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(color.opacity(0.45)),
                            lineWidth: 1
                        )
                    }

                    // خطوط النجوم على الجانبين
                    let connections: [[CGPoint]] = [
                        [
                            CGPoint(x: 25, y: 168),
                            CGPoint(x: 51, y: 221),
                            CGPoint(x: 25, y: 292)
                        ],
                        [
                            CGPoint(x: 362, y: 189),
                            CGPoint(x: 350, y: 330)
                        ]
                    ]

                    for points in connections {
                        var path = Path()

                        for (index, point) in points.enumerated() {
                            let position = CGPoint(
                                x: point.x * sx,
                                y: point.y * sy
                            )

                            if index == 0 {
                                path.move(to: position)
                            } else {
                                path.addLine(to: position)
                            }
                        }

                        context.stroke(
                            path,
                            with: .color(color.opacity(0.45)),
                            lineWidth: 1
                        )
                    }

                    // نقاط صغيرة موزعة على الخلفية
                    let dots: [CGPoint] = [
                        CGPoint(x: 25, y: 168),
                        CGPoint(x: 51, y: 221),
                        CGPoint(x: 25, y: 292),
                        CGPoint(x: 362, y: 189),
                        CGPoint(x: 350, y: 330),
                        CGPoint(x: 32, y: 590),
                        CGPoint(x: 361, y: 638),
                        CGPoint(x: 23, y: 713),
                        CGPoint(x: 319, y: 763)
                    ]

                    for dot in dots {
                        let rect = CGRect(
                            x: dot.x * sx - 1.5,
                            y: dot.y * sy - 1.5,
                            width: 3,
                            height: 3
                        )

                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(color.opacity(0.6))
                        )
                    }

                    // لمعات على شكل +
                    let sparkles: [CGPoint] = [
                        CGPoint(x: 40, y: 120),
                        CGPoint(x: 356, y: 290),
                        CGPoint(x: 44, y: 688),
                        CGPoint(x: 318, y: 808)
                    ]

                    for sparkle in sparkles {
                        let x = sparkle.x * sx
                        let y = sparkle.y * sy

                        var path = Path()
                        path.move(to: CGPoint(x: x - 3, y: y))
                        path.addLine(to: CGPoint(x: x + 3, y: y))
                        path.move(to: CGPoint(x: x, y: y - 3))
                        path.addLine(to: CGPoint(x: x, y: y + 3))

                        context.stroke(
                            path,
                            with: .color(color.opacity(0.6)),
                            lineWidth: 1
                        )
                    }
                }
            }
            .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// المدار المحيط بشخصية النجمة
struct StarOrbit: View {
    private let orbitColor = AppTheme.orbit

    var body: some View {
        ZStack {
            Circle()
                .stroke(orbitColor.opacity(0.8), lineWidth: 1)
                .frame(width: 248, height: 248)

            Circle()
                .stroke(orbitColor.opacity(0.8), lineWidth: 1)
                .frame(width: 230, height: 230)

            Ellipse()
                .stroke(orbitColor.opacity(0.9), lineWidth: 1)
                .frame(width: 292, height: 100)
                .rotationEffect(.degrees(-18))

            ForEach(0..<12) { index in
                Rectangle()
                    .fill(orbitColor)
                    .frame(width: 1, height: 6)
                    .offset(y: -124)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            Circle()
                .fill(orbitColor)
                .frame(width: 6, height: 6)
                .offset(x: -117, y: 45)

            Text("+")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(orbitColor)
                .offset(x: 83, y: -85)

            Text("+")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(orbitColor)
                .offset(x: -90, y: -105)
        }
        .frame(width: 310, height: 280)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
