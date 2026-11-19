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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(habitStore)
        }
    }
}
