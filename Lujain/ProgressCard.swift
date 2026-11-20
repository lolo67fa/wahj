import SwiftUI

struct ProgressCard: View {
    let completedPoints: Int
    let goalPoints: Int
    let completedHabitCount: Int
    let totalHabitCount: Int
    let pointsTowardNextStar: Int
    let currentStarNumber: Int
    let litStarsInConstellation: Int
    let completedConstellations: Int

    private var dailyProgress: Double {
        guard goalPoints > 0 else { return 0 }
        return min(Double(completedPoints) / Double(goalPoints), 1)
    }

    private var starProgress: Double {
        Double(pointsTowardNextStar) / Double(ConstellationProgress.pointsPerStar)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            DailyProgressSection(
                completedPoints: completedPoints,
                goalPoints: goalPoints,
                completedHabitCount: completedHabitCount,
                totalHabitCount: totalHabitCount,
                progress: dailyProgress
            )

            Divider()
                .overlay(AppTheme.text.opacity(0.25))

            StarProgressSection(
                pointsTowardNextStar: pointsTowardNextStar,
                currentStarNumber: currentStarNumber,
                litStarsInConstellation: litStarsInConstellation,
                completedConstellations: completedConstellations,
                progress: starProgress
            )
        }
        .foregroundStyle(AppTheme.text)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 215)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.elevated)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "تقدم اليوم: \(completedPoints) من \(goalPoints) نقطة. النجمة \(currentStarNumber): \(pointsTowardNextStar) من ١٠٠ نقطة"
        )
    }
}

struct DailyProgressSection: View {
    let completedPoints: Int
    let goalPoints: Int
    let completedHabitCount: Int
    let totalHabitCount: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("تقدمك اليوم")
                .font(.headline)

            Text("\(completedPoints) / \(goalPoints) نقطة")
                .font(.title2.bold())

            Text("\(completedHabitCount) من \(totalHabitCount) عادات مكتملة")
                .font(.caption)
                .foregroundStyle(AppTheme.text.opacity(0.75))

            ProgressView(value: progress)
                .tint(Color(hex: "FBEFC8"))
                .scaleEffect(y: 1.5)
                .padding(.vertical, 3)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct StarProgressSection: View {
    let pointsTowardNextStar: Int
    let currentStarNumber: Int
    let litStarsInConstellation: Int
    let completedConstellations: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Label("النجمة \(currentStarNumber)", systemImage: "sparkle")
                .font(.headline)

            Text("\(pointsTowardNextStar) / ١٠٠ نقطة")
                .font(.caption.bold())
                .foregroundStyle(Color(hex: "FBEFC8"))

            ProgressView(value: progress)
                .tint(Color(hex: "FBEFC8"))
                .scaleEffect(y: 1.5)
                .padding(.vertical, 3)

            HStack(spacing: 3) {
                ForEach(0..<ConstellationProgress.starsPerConstellation, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundStyle(
                            index < litStarsInConstellation
                            ? Theme.cream
                            : AppTheme.text.opacity(0.28)
                        )
                }
            }

            Text("كوكبات مكتملة: \(completedConstellations)")
                .font(.caption2)
                .foregroundStyle(AppTheme.text.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
