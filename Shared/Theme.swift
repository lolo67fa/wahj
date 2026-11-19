import SwiftUI

// The team's color names, now taken from the one palette in AppTheme.
enum Theme {
    static let bg        = AppTheme.background
    static let card      = AppTheme.surface
    static let border    = AppTheme.border
    static let pink      = AppTheme.accent
    static let cream     = AppTheme.cream
    static let tabActive = AppTheme.elevated
}

extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}
