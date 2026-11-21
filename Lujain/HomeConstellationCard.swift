import SwiftUI

// The big card in the middle of the home page: the constellation the user chose on
// «اختار نجمتك», drawn with the same shape, positions and card background as that
// page. The light moves along its path as points come in (5 per completed habit).
struct HomeConstellationCard: View {
    let index: Int
    let points: Int
    // The next constellation opens when this one reaches 100.
    let nextUnlocked: Bool

    // The card is the night sky in both modes, so its text stays light.
    private let pink = AppTheme.onSkyAccent
    private let secondary = AppTheme.onSkySecondary

    private var name: String { StarProgress.names[index] }
    private var isComplete: Bool { points >= HabitProgress.pointsPerConstellation }

    private var nextName: String? {
        StarProgress.names.indices.contains(index + 1) ? StarProgress.names[index + 1] : nil
    }

    var body: some View {
        ZStack {
            ConstellationCardBackground(seed: index)

            VStack(alignment: .leading, spacing: 10) {
                // الرسم هو العنصر الأساسي في البطاقة.
                ConstellationDrawing(
                    index: index,
                    progress: Double(points) / Double(HabitProgress.pointsPerConstellation),
                    locked: false,
                    lightsAlongPath: true
                )
                .frame(height: 160)
                .padding(.horizontal, 24)
                .padding(.top, 6)

                HStack(alignment: .firstTextBaseline) {
                    Text(name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.onSky)

                    Spacer(minLength: 8)

                    Text("\(arabicNumber(points)) / \(arabicNumber(HabitProgress.pointsPerConstellation)) نقطة")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(pink)
                        .contentTransition(.numericText())
                }

                Text(footnote)
                    .font(.system(size: 12))
                    .foregroundStyle(secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(pink.opacity(0.35), lineWidth: 1)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.3), radius: 0, y: 4)
        .environment(\.layoutDirection, .rightToLeft)
        .animation(.snappy, value: points)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("المجموعة النجمية \(name)")
        .accessibilityValue("\(arabicNumber(points)) من ١٠٠ نقطة")
        .accessibilityHint("يفتح صفحة نجومي")
    }

    private var footnote: String {
        if isComplete, let nextName, nextUnlocked {
            return "اكتملت! انفتحت «\(nextName)»، اختارها من نجمتي"
        }
        if isComplete {
            return "اكتملت \(name)!"
        }
        return "كل مجموعة نجمية تحتاج ١٠٠ نقطة"
    }
}

#Preview {
    VStack(spacing: 20) {
        HomeConstellationCard(index: 0, points: 35, nextUnlocked: false)
        HomeConstellationCard(index: 1, points: 100, nextUnlocked: true)
    }
    .padding()
    .background(Theme.bg)
}
