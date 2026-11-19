import SwiftUI

enum Theme {
    static let bg        = Color("ThemeBg")
    static let card      = Color("ThemeCard")
    static let border    = Color("ThemeBorder")
    static let pink      = Color("ThemePink")
    static let cream     = Color("ThemePoints")   // warm text accent (Figma text/points)
    static let tabActive = Color("ThemeTabActive")
    static let text      = Color("ThemeText")
    static let onAccent  = Color("ThemeOnAccent")
    static let decorLine = Color("ThemeDecorLine")
    static let starLit   = Color("ThemeStarLit")
}

extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}
