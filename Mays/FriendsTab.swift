import SwiftUI
import LinkPresentation

// صفحات الأصدقاء كلها هنا:
// الأصدقاء (زها) ← ابدأ عادة مع صديق ← اختيار العادة (زها) ← اختيار النجمة ← إرسال الدعوة
// وبعد ما تبدأ رحلة مشتركة: صفحة الرحلة (أعضاء، تقدم، ستريك، دعوة صديقة).
enum FriendsRoute: Hashable {
    case chooseHabit
    case chooseStar(habitID: UUID)
}

struct FriendsTab: View {
    @Binding var selectedTab: Int
    @Environment(JourneyService.self) private var service

    // الصفحات المفتوحة
    @State private var path: [FriendsRoute] = []
    // الرحلة المعروضة لو عندك أكثر من رحلة
    @State private var selectedJourneyID: String?

    private var currentState: JourneyState? {
        if let selectedJourneyID, let state = service.state(for: selectedJourneyID) { return state }
        return service.states.first
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let currentState {
                    FriendsListView(
                        state: currentState,
                        allStates: service.states,
                        selectedTab: $selectedTab,
                        onSelectJourney: { selectedJourneyID = $0 },
                        onStartNew: { path.append(.chooseHabit) }
                    )
                } else {
                    // أول صفحة (زها): ما فيه رحلات مشتركة بعد
                    FriendsScreen(selectedTab: $selectedTab)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: FriendsRoute.self) { route in
                switch route {
                case .chooseHabit:
                    StartHabitTogetherScreen { habit in
                        path.append(.chooseStar(habitID: habit.id))
                    }
                case .chooseStar(let habitID):
                    FriendChooseStarView(habitID: habitID) { journeyID in
                        // بعد الدعوة نرجع لأول صفحة وتظهر الرحلة
                        selectedJourneyID = journeyID
                        path = []
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Share sheet

// نافذة المشاركة الأصلية في iOS، وتقول لنا اذا انرسلت او لا.
// فيها «نسخ» تلقائيًا لنسخ الرابط والرمز.
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

// محتوى الدعوة: رسالة عربية فيها الرابط ورمز الدعوة، وصورة نُجيمة فوق النافذة.
// الرابط ما فيه أي بيانات شخصية، فقط رمز عشوائي.
final class InviteItem: NSObject, UIActivityItemSource {
    let text: String
    let url: URL

    init(text: String, url: URL) {
        self.text = text
        self.url = url
    }

    convenience init(invite: InviteSummary) {
        let star = StarProgress.names[min(max(invite.constellationIndex, 0), StarProgress.names.count - 1)]
        let text = """
        تعالي نكمل نجمة «\(star)» سوا في وَهج ✨
        عادتنا: \(invite.habitTitle)
        رمز الدعوة: \(InviteCode.formatted(invite.code))
        """
        self.init(text: text, url: InviteCode.webLink(for: invite.code))
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
        info.originalURL = url
        if let image = UIImage(named: "starCharacter") {
            info.iconProvider = NSItemProvider(object: image)
        }
        return info
    }
}

#Preview {
    FriendsTab(selectedTab: .constant(3))
        .environment(HabitStore.preview)
        .environment(JourneyService())
}
