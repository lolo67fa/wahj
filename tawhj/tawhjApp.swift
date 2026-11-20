import SwiftUI
import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct tawhjApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var delegate

    // مصدر بيانات واحد للعادات تستخدمه كل الصفحات.
    @State private var habitStore = HabitStore()
    // الرحلات المشتركة مع الأصدقاء (Firestore) والدعوات اللي وصلت.
    @State private var journeyService = JourneyService()
    @State private var inviteInbox = InviteInbox()
    // فاتح / داكن / حسب الجهاز — من صفحة المظهر في البداية أو الإعدادات.
    @AppStorage("appearance") private var appearance = Appearance.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(habitStore)
                .environment(journeyService)
                .environment(inviteInbox)
                .preferredColorScheme(appearance.colorScheme)
                // wahj://invite/CODE أو https://wahj-ad44b.web.app/i/CODE
                // تنحفظ الدعوة وتفتح بعد تسجيل الدخول والتهيئة.
                .onOpenURL { url in
                    if let code = InviteCode.from(url: url) { inviteInbox.receive(code) }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL, let code = InviteCode.from(url: url) {
                        inviteInbox.receive(code)
                    }
                }
        }
    }
}
