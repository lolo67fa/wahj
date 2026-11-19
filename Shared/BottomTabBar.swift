import SwiftUI

struct BottomTabBar: View {
    let items: [(title: String, icon: String)] = [
        ("الرئيسية", "tab_home"),
        ("عاداتي", "tab_habits"),
        ("نجمتي", "tab_stars"),
        ("أصدقائي", "tab_friends")
    ]
    @Binding var selected: Int
    
    var body: some View {
        HStack {
            ForEach(items.indices, id: \.self) { i in
                VStack(spacing: 4) {
                    Image(items[i].icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                    Text(items[i].title).font(.caption2)
                }
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected == i ? Theme.tabActive : Color.clear, in: Capsule())
                .onTapGesture { selected = i }
            }
        }
        .padding(6)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
    }
}
