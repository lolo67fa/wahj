import SwiftUI

// App colors. Each one is a Color Set in Assets.xcassets with a Light (Any)
// and a Dark version, so SwiftUI picks the right one automatically.
// Light = Figma "Light" colors. Dark = the original dark theme.
enum Theme {
    static let bg            = Color("ThemeBg")
    static let card          = Color("ThemeCard")
    static let border        = Color("ThemeBorder")
    static let pink          = Color("ThemePink")
    static let cream         = Color("ThemeCream")
    static let tabActive     = Color("ThemeTabActive")

    static let text          = Color("ThemeText")           // text and icons (was .white)
    static let onAccent      = Color("ThemeOnAccent")       // text/icons on pink buttons
    static let decorLine     = Color("ThemeDecorLine")      // background circles
    static let decorDot      = Color("ThemeDecorDot")       // background dot and sparkle
    static let starLit       = Color("ThemeStarLit")        // filled star
}

// The user's appearance choice, saved with @AppStorage("appearance").
// MyApp applies it to the whole app; any screen can change it.
enum Appearance: String, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: "تلقائي"
        case .light:  "فاتح"
        case .dark:   "داكن"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon"
        }
    }

    // nil = follow the iPhone's setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}
