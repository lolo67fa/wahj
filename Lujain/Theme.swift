import SwiftUI

enum Theme {
    static let bg        = Color(hex: "2F2240")
    static let card      = Color(hex: "3F2B55")
    static let border    = Color(hex: "5A3F73")
    static let pink      = Color(hex: "E6B4E1")
    static let cream     = Color(hex: "FBEFC8")
    static let tabActive = Color(hex: "9B6BC0")
}

extension Color {
    init(hex: String) {
        let v = UInt64(hex, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}
