import SwiftUI

//  الثريا
struct PleiadesPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .pleiades, onNext: onNext) }
}
//الدب الأكبر
struct BigDipperPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .bigDipper, onNext: onNext) }
}
//  الجبار
struct OrionPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .orion, onNext: onNext) }
}

//  ذات الكرسي
struct CassiopeiaPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .cassiopeia, onNext: onNext) }
}

//  العقرب
struct ScorpiusPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .scorpius, onNext: onNext) }
}

// الدب الأصغر
struct LittleDipperPage: View {
    var onNext: () -> Void = {}
    var body: some View { ConstellationCompletionPage(spec: .littleDipper, onNext: onNext) }
}

// Star positions
extension ConstellationSpec {

    static let pleiades = ConstellationSpec(
        points: [
            CGPoint(x: 0.50, y: 0.05),  // 0 top
            CGPoint(x: 0.76, y: 0.22),  // 1
            CGPoint(x: 0.92, y: 0.50),  // 2 right
            CGPoint(x: 0.74, y: 0.78),  // 3
            CGPoint(x: 0.50, y: 0.95),  // 4 bottom
            CGPoint(x: 0.28, y: 0.78),  // 5
            CGPoint(x: 0.22, y: 0.50),  // 6 left
            CGPoint(x: 0.26, y: 0.22),  // 7
            CGPoint(x: 0.50, y: 0.50),  // 8 center
            CGPoint(x: 0.00, y: 0.50)   // 9 tail
        ],
        segments: [(9,6), (6,7), (7,0), (0,1), (1,2), (2,3), (3,4), (4,5), (5,6)],
        size: CGSize(width: 210, height: 200)
    )

    static let orion = ConstellationSpec(
        points: [
            CGPoint(x: 0.20, y: 0.02),  // 0 left top
            CGPoint(x: 0.82, y: 0.00),  // 1 right top
            CGPoint(x: 0.32, y: 0.30),  // 2 left shoulder
            CGPoint(x: 0.72, y: 0.28),  // 3 right shoulder
            CGPoint(x: 0.42, y: 0.55),  // 4 belt left
            CGPoint(x: 0.60, y: 0.55),  // 5 belt right
            CGPoint(x: 0.28, y: 0.95),  // 6 left foot
            CGPoint(x: 0.82, y: 0.90)   // 7 right foot
        ],
        segments: [(0,2), (1,3), (2,3), (2,4), (3,5), (4,5), (4,6), (5,7), (6,7)],
        size: CGSize(width: 170, height: 210)
    )

    static let cassiopeia = ConstellationSpec(
        points: [
            CGPoint(x: 0.00, y: 0.15),
            CGPoint(x: 0.25, y: 0.85),
            CGPoint(x: 0.50, y: 0.35),
            CGPoint(x: 0.75, y: 0.90),
            CGPoint(x: 1.00, y: 0.20)
        ],
        segments: [(0,1), (1,2), (2,3), (3,4)],
        size: CGSize(width: 250, height: 110)
    )

    static let scorpius = ConstellationSpec(
        points: [
            CGPoint(x: 0.88, y: 0.02),  // 0 claw top
            CGPoint(x: 0.94, y: 0.22),  // 1
            CGPoint(x: 0.98, y: 0.42),  // 2
            CGPoint(x: 0.70, y: 0.28),  // 3
            CGPoint(x: 0.48, y: 0.48),  // 4
            CGPoint(x: 0.40, y: 0.72),  // 5
            CGPoint(x: 0.30, y: 0.92),  // 6
            CGPoint(x: 0.15, y: 0.93),  // 7
            CGPoint(x: 0.04, y: 0.78),  // 8
            CGPoint(x: 0.06, y: 0.58)   // 9 tail tip
        ],
        segments: [(0,1), (1,2), (1,3), (3,4), (4,5), (5,6), (6,7), (7,8), (8,9)],
        size: CGSize(width: 220, height: 200)
    )

    static let littleDipper = ConstellationSpec(
        points: [
            CGPoint(x: 0.00, y: 0.50),  // 0 handle tip
            CGPoint(x: 0.28, y: 0.28),  // 1
            CGPoint(x: 0.50, y: 0.32),  // 2
            CGPoint(x: 0.72, y: 0.55),  // 3 bowl corner
            CGPoint(x: 0.97, y: 0.62),  // 4
            CGPoint(x: 0.95, y: 0.95),  // 5
            CGPoint(x: 0.74, y: 0.88)   // 6
        ],
        segments: [(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,3)],
        softFrom: 3,   // the bowl gets the thick glowing lines
        size: CGSize(width: 240, height: 160)
    )

    static let bigDipper = ConstellationSpec(
        points: [
            CGPoint(x: 0.07, y: 0.18),   // 0 handle tip
            CGPoint(x: 0.23, y: 0.10),   // 1
            CGPoint(x: 0.36, y: 0.23),   // 2
            CGPoint(x: 0.50, y: 0.43),   // 3 bowl corner
            CGPoint(x: 0.92, y: 0.47),   // 4
            CGPoint(x: 0.87, y: 0.91),   // 5
            CGPoint(x: 0.52, y: 0.83)    // 6
        ],
        segments: [(0,1), (1,2), (2,3), (3,4), (4,5), (5,6), (6,3)],
        softFrom: 3,   // the bowl gets the thick glowing lines
        size: CGSize(width: 230, height: 180)
    )
}

#Preview("الدب الأكبر") { BigDipperPage() }
#Preview("الثريا") { PleiadesPage() }
#Preview("الجبار") { OrionPage() }
#Preview("ذات الكرسي") { CassiopeiaPage() }
#Preview("العقرب") { ScorpiusPage() }
#Preview("الدب الأصغر") { LittleDipperPage() }
