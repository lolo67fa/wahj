import SwiftUI

struct FriendsListView: View {
    // الالوان
    let background = Color(red: 51/255, green: 32/255, blue: 63/255)
    let card = Color(red: 75/255, green: 47/255, blue: 92/255)
    let pink = Color(red: 242/255, green: 179/255, blue: 230/255)
    let yellow = Color(red: 0.96, green: 0.85, blue: 0.54)

    // اسم النجمة جاي من FriendsTab
    @Binding var sharedStar: String
    // الصفحات المفتوحة، نضيف لها عشان ننتقل
    @Binding var path: [String]

    // نفتح نافذة المشاركة او لا
    @State var showInvite = false

    // الصديقات: الاسم وعدد الايام
    let friends = [
        ("سارة", "١٢ يوم"),
        ("ريم", "٣ أيام"),
        ("نورة", "يومين")
    ]

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {

                Text("الأصدقاء")
                    .font(.title.bold())

                // بطاقة النجمة اللي نكملها سوا
                VStack(alignment: .leading) {
                    Text("نجمتنا سوا · \(sharedStar)")
                        .font(.footnote.bold())
                    Spacer()
                    FriendsConstellationView()
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding()
                .frame(height: 170)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Text("صديقاتك")
                    .font(.footnote.bold())

                // صف لكل صديقة
                ForEach(friends, id: \.0) { friend in
                    HStack {
                        // اول حرف من الاسم داخل دائرة
                        Text(String(friend.0.prefix(1)))
                            .frame(width: 36, height: 36)
                            .background(background)
                            .clipShape(Circle())
                        Text(friend.0)
                            .bold()
                        Spacer()
                        // عدد الايام
                        Text("🔥 " + friend.1)
                            .font(.footnote.bold())
                            .foregroundStyle(yellow)
                    }
                    .padding(12)
                    .background(card)
                    .clipShape(Capsule())
                }

                Spacer()

                // زر الدعوة يفتح نافذة المشاركة
                Button {
                    showInvite = true
                } label: {
                    Text("+ دعوة صديقة للانضمام")
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            // اطار منقط
                            Capsule().stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                }
                // نافذة المشاركة حقت ابل
                .sheet(isPresented: $showInvite) {
                    ShareSheet(items: [InviteItem(text: "تعالي نبدأ عادة سوا في وَهج ✨",
                                                  url: URL(string: "wahaj://invite")!)]) { _ in
                        showInvite = false
                    }
                    .presentationDetents([.medium, .large])
                }

                // ينقلنا لصفحة اختيار العادة
                Button {
                    path.append("habit")
                } label: {
                    Text("ابدأ عادة مع صديق")
                        .bold()
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pink)
                        .clipShape(Capsule())
                }
            }
            .padding()
            .foregroundStyle(.white)
        }
        // الصفحة من اليمين لليسار
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// رسمة النجمة المشتركة
struct FriendsConstellationView: View {
    // اماكن النجوم
    let points = [
        CGPoint(x: 30, y: 20),
        CGPoint(x: 90, y: 80),
        CGPoint(x: 150, y: 35),
        CGPoint(x: 210, y: 80),
        CGPoint(x: 270, y: 30)
    ]
    // كم نجمة انضاءت
    let done = 2

    var body: some View {
        ZStack {
            // خط منقط على كل النجوم
            Path { path in
                path.addLines(points)
            }
            .stroke(Color.white.opacity(0.6),
                    style: StrokeStyle(lineWidth: 2, dash: [5]))

            // خط ابيض بين النجوم اللي انضاءت بس
            Path { path in
                path.addLines(Array(points.prefix(done)))
            }
            .stroke(Color.white, lineWidth: 3)

            ForEach(0..<points.count, id: \.self) { i in
                if i < done {
                    // نجمة مضيئة
                    Image(systemName: "sparkle")
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.30))
                        .padding(8)
                        .background(Color(red: 1.0, green: 0.85, blue: 0.30).opacity(0.25))
                        .clipShape(Circle())
                        .position(points[i])
                } else {
                    // نجمة باقي ما انضاءت
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .position(points[i])
                }
            }
        }
        .frame(width: 300, height: 100)
        // عشان الرسمة ما تنقلب
        .environment(\.layoutDirection, .leftToRight)
    }
}

#Preview {
    NavigationStack {
        FriendsListView(sharedStar: .constant("ذات الكرسي"), path: .constant([]))
    }
}
