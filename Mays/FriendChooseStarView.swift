import SwiftUI

struct FriendStarInfo {
    let name: String
    let points: [CGPoint]
}

struct FriendChooseStarView: View {
    let background = Theme.bg
    let pink = Theme.pink

    @AppStorage("completedStars") var completedStars = 5

    // وصلة لاسم النجمة
    @Binding var selected: String

    // وش يصير بعد ما تنرسل الدعوة (يجي من FriendsTab)
    let onFinish: () -> Void

    @State var showShare = false   // نفتح نافذة المشاركة؟
    @State var didShare = false    // انرسلت الدعوة؟

    let allStars: [FriendStarInfo] = [
        FriendStarInfo(name: "الثريا", points: [
            CGPoint(x: 10, y: 50), CGPoint(x: 40, y: 50),
            CGPoint(x: 55, y: 20), CGPoint(x: 75, y: 10),
            CGPoint(x: 95, y: 20), CGPoint(x: 110, y: 50),
            CGPoint(x: 95, y: 80), CGPoint(x: 75, y: 90),
            CGPoint(x: 55, y: 80), CGPoint(x: 40, y: 50)
        ]),
        FriendStarInfo(name: "الجبار", points: [
            CGPoint(x: 110, y: 10), CGPoint(x: 90, y: 40),
            CGPoint(x: 90, y: 60), CGPoint(x: 105, y: 90),
            CGPoint(x: 45, y: 90), CGPoint(x: 60, y: 60),
            CGPoint(x: 60, y: 40), CGPoint(x: 40, y: 10)
        ]),
        FriendStarInfo(name: "ذات الكرسي", points: [
            CGPoint(x: 10, y: 20), CGPoint(x: 40, y: 80),
            CGPoint(x: 75, y: 40), CGPoint(x: 110, y: 85),
            CGPoint(x: 145, y: 25)
        ]),
        FriendStarInfo(name: "الدب الأصغر", points: [
            CGPoint(x: 10, y: 40), CGPoint(x: 40, y: 25),
            CGPoint(x: 70, y: 35), CGPoint(x: 95, y: 55),
            CGPoint(x: 140, y: 55), CGPoint(x: 140, y: 90),
            CGPoint(x: 95, y: 90), CGPoint(x: 95, y: 55)
        ]),
        FriendStarInfo(name: "العقرب", points: [
            CGPoint(x: 140, y: 10), CGPoint(x: 130, y: 30),
            CGPoint(x: 110, y: 40), CGPoint(x: 85, y: 50),
            CGPoint(x: 65, y: 70), CGPoint(x: 55, y: 90),
            CGPoint(x: 30, y: 95), CGPoint(x: 15, y: 80)
        ]),
        FriendStarInfo(name: "الدب الأكبر", points: [
            CGPoint(x: 10, y: 25), CGPoint(x: 35, y: 12),
            CGPoint(x: 60, y: 28), CGPoint(x: 85, y: 45),
            CGPoint(x: 90, y: 85), CGPoint(x: 135, y: 90),
            CGPoint(x: 140, y: 50), CGPoint(x: 85, y: 45)
        ])
    ]

    var unlockedStars: [FriendStarInfo] {
        Array(allStars.prefix(completedStars + 1))
    }

    // رابط الدعوة فيه رقم النجمة
    var inviteLink: URL {
        let starNumber = allStars.firstIndex { $0.name == selected } ?? 0
        return URL(string: "wahaj://invite?star=\(starNumber)")!
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Text("اختار نجمتكم")
                        .font(.title.bold())
                    Spacer()
                }

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(unlockedStars, id: \.name) { star in
                            FriendStarCard(name: star.name,
                                           points: star.points,
                                           isSelected: selected == star.name)
                                .onTapGesture { selected = star.name }
                        }
                    }
                }

                // زر إرسال الدعوة
                Button {
                    showShare = true
                } label: {
                    Text("التالي: إرسال الدعوة")
                        .bold()
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pink)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .foregroundStyle(Theme.text)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if !unlockedStars.contains(where: { $0.name == selected }) {
                selected = unlockedStars.first?.name ?? ""
            }
        }
        // نافذة المشاركة
        .sheet(isPresented: $showShare, onDismiss: {
            // لما تتسكر النافذة: لو انرسلت الدعوة نروح لصفحة الأصدقاء
            if didShare { onFinish() }
        }) {
            ShareSheet(items: [InviteItem(text: "تعالي نكمل نجمة \(selected) سوا في وَهج ✨", url: inviteLink)]) { completed in
                didShare = completed
                showShare = false
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct FriendStarCard: View {
    let name: String
    let points: [CGPoint]
    let isSelected: Bool

    let card = Theme.card
    let pink = Theme.pink

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.title3.bold())
                if isSelected {
                    Text("مختارة")
                        .font(.footnote)
                        .foregroundStyle(pink)
                }
            }
            Spacer()
            FriendStarDrawing(points: points)
        }
        .padding()
        .background(card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(pink, lineWidth: isSelected ? 2 : 0)
        )
    }
}

struct FriendStarDrawing: View {
    let points: [CGPoint]
    let yellow = Theme.starLit

    let width: CGFloat = 120
    let height: CGFloat = 70
    let margin: CGFloat = 10

    var fittedPoints: [CGPoint] {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1

        let scale = min((width - margin * 2) / max(maxX - minX, 1),
                        (height - margin * 2) / max(maxY - minY, 1))

        let offsetX = (width - (maxX - minX) * scale) / 2
        let offsetY = (height - (maxY - minY) * scale) / 2

        return points.map {
            CGPoint(x: ($0.x - minX) * scale + offsetX,
                    y: ($0.y - minY) * scale + offsetY)
        }
    }

    var body: some View {
        ZStack {
            Path { path in
                path.addLines(fittedPoints)
            }
            .stroke(Theme.text.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

            ForEach(0..<fittedPoints.count, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 10))
                    .foregroundStyle(yellow)
                    .shadow(color: yellow, radius: 3)
                    .position(fittedPoints[i])
            }
        }
        .frame(width: width, height: height)
        .environment(\.layoutDirection, .leftToRight)
    }
}

#Preview {
    FriendChooseStarView(selected: .constant("الثريا"), onFinish: {})
}
