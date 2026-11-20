import SwiftUI

struct StarsView: View {
    let progress: ConstellationProgress

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.cream)
                    .padding(.top, 20)

                Text("نجومي")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(AppTheme.text)

                VStack(spacing: 12) {
                    StatRow(title: "النجمة الحالية", value: "\(progress.currentStarNumber)")
                    StatRow(title: "النجوم المضاءة في الكوكبة", value: "\(progress.litStarsInCurrentConstellation)")
                    StatRow(title: "الكوكبات المكتملة", value: "\(progress.completedConstellations)")
                    StatRow(title: "نقاط للنجمة التالية", value: "\(progress.pointsTowardNextStar)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .environment(\.layoutDirection, .rightToLeft)
        .background { StarryBackground() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.text)
            Spacer()
            Text(value)
                .bold()
                .foregroundStyle(Theme.cream)
        }
        .padding(16)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.border, lineWidth: 1)
        }
    }
}
