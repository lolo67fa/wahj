//
//  AppTheme.swift
//  Shared
//
//  The one color palette for every screen in Wahj. The values come from the
//  colors already used on the sign-in / onboarding / star selection screens
//  (and the same ones in the friends screens), so nothing here is new.
//  Use these names instead of writing Color(red:green:blue:) in a view.
//
//  The space background (SpaceBackground, StarryBackground), the orbits
//  (StarOrbit, OrbitRings) and the gold star light keep their own colors.
//

import SwiftUI

enum AppTheme {
    // MARK: Surfaces

    /// Dark purple behind every screen.  #33203F
    static let background = rgb(51, 32, 63)
    /// Cards, rows, the tab bar.  #4B2F5C
    static let surface = rgb(75, 47, 92)
    /// Text fields and softer cards.  #432A52
    static let field = rgb(67, 42, 82)
    /// The lighter purple: featured cards, constellation cards, the selected tab.  #6E3F8A
    static let elevated = rgb(110, 63, 138)
    /// Thin borders around cards, rows and fields.  #6A4A7C
    static let border = rgb(106, 74, 124)

    // MARK: Accent

    /// Pink for buttons, selection, toggles and active icons.  #F2B3E6
    static let accent = rgb(242, 179, 230)
    /// Text and icons on top of a pink button.  Same as the background.
    static let onAccent = background
    /// The solid shadow under pink buttons.  #591258
    static let accentShadow = rgb(89, 18, 88)

    // MARK: Text

    /// Main text: white with a touch of pink.  #FFF4FD
    static let text = rgb(255, 244, 253)
    /// Secondary text and captions.  #E3C8EA
    static let textSecondary = rgb(227, 200, 234)
    /// Disabled controls keep their color at this opacity.
    static let disabledOpacity = 0.5

    // MARK: Light and states

    /// Gold light for stars and achievements (unchanged).  #FFEBA6
    static let gold = rgb(255, 235, 166)
    /// Soft cream used for completed icons and the selected day.  #FBEFC8
    static let cream = rgb(251, 239, 200)
    /// Errors stay clearly red-pink against the purple.  #FF8A9A
    static let error = rgb(255, 138, 154)
    /// Success uses the gold light.
    static let success = gold

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
