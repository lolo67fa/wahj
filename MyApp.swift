import SwiftUI

@main struct MyApp: App {
    // Light / dark / follow iPhone — chosen by the user, remembered between launches.
    @AppStorage("appearance") private var appearance = Appearance.system

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}
