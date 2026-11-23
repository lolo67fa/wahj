//
//  AppTheme.swift
//  Shared
//
//  The one color palette for every screen in Wahj, in light and dark.
//  Each color is a Color Set in Wahj/Assets.xcassets (Theme…) with an Any
//  (light) and a Dark value, so SwiftUI picks the right one for the
//  appearance chosen in onboarding or Settings.
//    Dark  = the unified palette (#33203F background, #4B2F5C cards, #F2B3E6 pink…)
//    Light = the team's Figma light colors (Lamis's light mode)
//  Use these names (or Theme's, which point to the same Color Sets) instead of
//  writing Color(red:green:blue:) in a view.
//

import SwiftUI

enum AppTheme {
    // MARK: Surfaces

    /// Behind every screen.
    static let background = Color("ThemeBg")
    /// Cards, rows, the tab bar.
    static let surface = Color("ThemeCard")
    /// Text fields and softer cards.
    static let field = Color("ThemeField")
    /// The deep purple "sky": constellation cards, the selected tab.
    static let elevated = Color("ThemeSky")
    /// Thin borders around cards, rows and fields.
    static let border = Color("ThemeBorder")
    /// The orbit lines and dots of the space background.
    static let orbit = Color("ThemeOrbit")

    // MARK: Accent

    /// Pink for buttons, selection, toggles and active icons.
    static let accent = Color("ThemePink")
    /// Text and icons on top of a pink button.
    static let onAccent = Color("ThemeOnAccent")
    /// The solid shadow under pink buttons.
    static let accentShadow = Color("ThemeAccentShadow")

    // MARK: Text

    /// Main text.
    static let text = Color("ThemeText")
    /// Secondary text and captions.
    static let textSecondary = Color("ThemeTextSecondary")
    /// Disabled controls keep their color at this opacity.
    static let disabledOpacity = 0.5

    // MARK: On the night-sky cards (constellation cards stay deep purple in both modes)

    static let onSky = rgb(255, 244, 253)
    static let onSkySecondary = rgb(227, 200, 234)
    static let onSkyAccent = rgb(242, 179, 230)

    // MARK: Light and states

    /// Gold light for stars and achievements.
    static let gold = Color("ThemeGold")
    /// Soft cream used for completed icons and the selected day.
    static let cream = Color("ThemeCream")
    /// Errors stay clearly red-pink in both modes.
    static let error = Color("ThemeError")
    /// Success uses the gold light.
    static let success = gold

    private static func rgb(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}
