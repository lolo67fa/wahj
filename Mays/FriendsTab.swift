import SwiftUI
import LinkPresentation

// هنا نربط صفحات الاصدقاء كلها
struct FriendsTab: View {
    // ارسلت دعوة قبل او لا
    @AppStorage("hasFriend") var hasFriend = false
    // النجمة والعادة المشتركة
    @AppStorage("sharedStar") var sharedStar = "الثريا"
    @AppStorage("sharedHabit") var sharedHabit = ""

    // الصفحات المفتوحة
    @State var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            // اول صفحة: فاضية او فيها صديقات
            Group {
                if hasFriend {
                    FriendsListView(sharedStar: $sharedStar, path: $path)
                } else {
                    FriendsEmptyView(path: $path)
                }
            }
            // كل كلمة تفتح صفحة
            .navigationDestination(for: String.self) { page in
                if page == "habit" {
                    FriendChooseHabitView(selectedHabit: $sharedHabit, path: $path)
                } else if page == "star" {
                    FriendChooseStarView(selected: $sharedStar) {
                        // بعد الدعوة
                        hasFriend = true
                        path = []   // نرجع لاول صفحة
                    }
                }
            }
        }
    }
}

// صفحة الاصدقاء لما تكون فاضية
struct FriendsEmptyView: View {
    @Binding var path: [String]

    let background = Theme.bg
    let card = Theme.card
    let pink = Theme.pink
    let yellow = Theme.starLit

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("الأصدقاء")
                    .font(.title.bold())
                Text("رحلة صغيرة.. ونور يجمعكم")
                    .font(.footnote)
                    .opacity(0.7)

                // بطاقة نجيمة
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(card)
                    Image("icon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                }
                .frame(height: 140)

                VStack(spacing: 8) {
                    Text("مع بعض، العادة أحلى")
                        .font(.title2.bold())
                    Text("عادة واحدة، أنتِ وصديقتك، ونجمة تنورونها سوا.")
                        .font(.footnote)
                        .opacity(0.7)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

                // يفتح صفحة اختيار العادة
                Button {
                    path.append("habit")
                } label: {
                    Text("ابدأ عادة مع صديق")
                        .bold()
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pink)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("لكل عادة رحلتها")
                        .bold()
                        .foregroundStyle(yellow)
                    Text("تقدرين تبدئين المشاركة مع صديق آخر.\nكل رحلة لها عادة وجدول ورصيد مستقل.")
                        .font(.footnote)
                        .opacity(0.7)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(card)
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()
            }
            .padding()
            .foregroundStyle(Theme.text)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// صفحة اختيار العادة
struct FriendChooseHabitView: View {
    @Binding var selectedHabit: String
    @Binding var path: [String]

    let background = Theme.bg
    let card = Theme.card
    let pink = Theme.pink

    // عادات المستخدمة
    let habits = [
        ("المشي", "من عاداتك · يوميًا"),
        ("القراءة", "من عاداتك · يوميًا")
    ]

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("ابدؤوا عادة سوا")
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Text("وش العادة اللي تبغون تبدؤونها سوا؟")
                    .font(.title2.bold())
                Text("اختاري عادة واحدة")
                    .font(.footnote)
                    .opacity(0.7)

                // بطاقة لكل عادة
                ForEach(habits, id: \.0) { habit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.0).bold()
                            Text(habit.1).font(.caption).opacity(0.7)
                        }
                        Spacer()
                        // دائرة الاختيار
                        Image(systemName: selectedHabit == habit.0 ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(pink)
                    }
                    .padding()
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(pink, lineWidth: selectedHabit == habit.0 ? 2 : 0)
                    )
                    .onTapGesture { selectedHabit = habit.0 }
                }

                Button {
                } label: {
                    Text("اضف عادة جديدة")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(card)
                        .clipShape(Capsule())
                }

                Spacer()

                // يفتح صفحة اختيار النجمة
                Button {
                    path.append("star")
                } label: {
                    Text("المتابعة")
                        .bold()
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pink)
                        .clipShape(Capsule())
                }
                // ما يشتغل الا اذا اختارت عادة
                .disabled(selectedHabit.isEmpty)
                .opacity(selectedHabit.isEmpty ? 0.5 : 1)
            }
            .padding()
            .foregroundStyle(Theme.text)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// نافذة المشاركة، وتقول لنا اذا انرسلت او لا
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onDone: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // يشتغل بعد ما تخلص المشاركة
        vc.completionWithItemsHandler = { _, completed, _, _ in
            onDone(completed)
        }
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// محتوى الدعوة: الرسالة والرابط وصورة نجيمة
class InviteItem: NSObject, UIActivityItemSource {
    let text: String
    let url: URL

    init(text: String, url: URL) {
        self.text = text
        self.url = url
    }

    func activityViewControllerPlaceholderItem(_ vc: UIActivityViewController) -> Any {
        text
    }

    // اللي ينرسل فعليا
    func activityViewController(_ vc: UIActivityViewController,
                                itemForActivityType type: UIActivity.ActivityType?) -> Any? {
        "\(text)\n\(url.absoluteString)"
    }

    // العنوان والصورة فوق النافذة
    func activityViewControllerLinkMetadata(_ vc: UIActivityViewController) -> LPLinkMetadata? {
        let info = LPLinkMetadata()
        info.title = "دعوة من وَهج"
        if let image = UIImage(named: "icon") {
            info.iconProvider = NSItemProvider(object: image)
        }
        return info
    }
}

#Preview {
    FriendsTab()
}
