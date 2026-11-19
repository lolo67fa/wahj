// xcode: set sdk=iOS
import SwiftUI

// MARK: - Theme

enum Theme {
    static let background = Color("ThemeBg")
    static let card = Color("ThemeCard")
    static let cardSoft = Color("ThemeCard")
    static let hero = Color("ThemeSky")
    static let pink = Color("ThemePink")
    static let purple = Color("ThemeTabActive")
    static let yellow = Color("ThemeStarLit")
    static let text = Color("ThemeText")
    static let subtle = Color("ThemeTextSecondary")

    private static func color(_ red: Double, _ green: Double, _ blue: Double) -> Color {
        Color(.sRGB, red: red / 255, green: green / 255, blue: blue / 255)
    }
}

struct AppBackground: View {
    var body: some View {
        Theme.background.ignoresSafeArea()
    }
}

// MARK: - Star mascot

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x / 100,
                    y: rect.minY + rect.height * y / 100)
        }

        var path = Path()
        path.move(to: point(50, 4))
        path.addCurve(to: point(66, 32), control1: point(56, 4), control2: point(64, 17))
        path.addCurve(to: point(97, 39), control1: point(80, 29), control2: point(99, 32))
        path.addCurve(to: point(78, 63), control1: point(94, 49), control2: point(87, 57))
        path.addCurve(to: point(82, 94), control1: point(86, 75), control2: point(90, 93))
        path.addCurve(to: point(50, 81), control1: point(75, 96), control2: point(59, 87))
        path.addCurve(to: point(17, 94), control1: point(40, 87), control2: point(25, 95))
        path.addCurve(to: point(22, 63), control1: point(9, 93), control2: point(14, 75))
        path.addCurve(to: point(3, 38), control1: point(13, 57), control2: point(5, 48))
        path.addCurve(to: point(33, 32), control1: point(1, 32), control2: point(22, 29))
        path.addCurve(to: point(50, 4), control1: point(35, 17), control2: point(44, 4))
        path.closeSubpath()
        return path
    }
}

struct StarMascot: View {
    var body: some View {
        ZStack {
            StarShape()
                .fill(RadialGradient(
                    colors: [Color(red: 1, green: 0.99, blue: 0.96), Color(red: 1, green: 0.92, blue: 0.73)],
                    center: .center, startRadius: 2, endRadius: 47
                ))
                .overlay {
                    StarShape().stroke(Color(red: 0.87, green: 0.69, blue: 0.35), lineWidth: 1)
                }
                .shadow(color: Theme.yellow.opacity(0.28), radius: 10)

            HStack(spacing: 65) {
                Image(systemName: "heart.fill").rotationEffect(.degrees(-32))
                Image(systemName: "heart.fill").rotationEffect(.degrees(32))
            }
            .font(.system(size: 9))
            .foregroundStyle(Color(red: 0.81, green: 0.62, blue: 0.32))
            .offset(y: -10)

            HStack(spacing: 21) {
                Ellipse().frame(width: 5, height: 8)
                Ellipse().frame(width: 5, height: 8)
            }
            .foregroundStyle(.black)
            .offset(y: -5)

            HStack(spacing: 35) {
                Ellipse().frame(width: 17, height: 10)
                Ellipse().frame(width: 17, height: 10)
            }
            .foregroundStyle(Color(red: 0.85, green: 0.49, blue: 0.55).opacity(0.25))
            .offset(y: 6)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addQuadCurve(to: CGPoint(x: 15, y: 0), control: CGPoint(x: 7.5, y: 3))
                path.addQuadCurve(to: .zero, control: CGPoint(x: 7.5, y: 8))
                path.closeSubpath()
            }
            .fill(Color(red: 0.40, green: 0.15, blue: 0.21))
            .frame(width: 15, height: 5)
            .offset(y: 8)

            Image(systemName: "sparkle")
                .font(.system(size: 6))
                .foregroundStyle(.white)
                .offset(x: 21, y: -24)
            Image(systemName: "sparkle")
                .font(.system(size: 7))
                .foregroundStyle(.white)
                .offset(x: -19, y: 46)
            Circle()
                .fill(.white)
                .frame(width: 3, height: 3)
                .offset(x: -11, y: -29)
        }
        .frame(width: 104, height: 104)
        .accessibilityHidden(true)
    }
}

// MARK: - Screen 1: الأصدقاء

struct FriendsScreen: View {
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("الأصدقاء")
                            .font(.system(size: 28, weight: .bold))
                        Text("رحلة صغيرة… ونور يجمعكم")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.subtle)
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.top, 12)
                    // Hero card
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Theme.hero)
                        .aspectRatio(2.19, contentMode: .fit)
                        .overlay {
                            ZStack {
                                Circle().stroke(Theme.background.opacity(0.26), lineWidth: 1)
                                    .frame(width: 226, height: 226)
                                Circle().stroke(Theme.background.opacity(0.26), lineWidth: 1)
                                    .frame(width: 266, height: 266)
                            }
                            .offset(x: 20)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Circle()
                                .fill(Theme.pink)
                                .frame(width: 300, height: 300)
                                .offset(x: -108, y: 215)
                        }
                        .overlay { StarMascot().offset(y: -9) }
                        .overlay(alignment: .topLeading) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.yellow)
                                .padding(.top, 41)
                                .padding(.leading, 25)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.yellow)
                                .padding(.bottom, 30)
                                .padding(.trailing, 38)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .padding(.top, 13)
                    VStack(spacing: 10) {
                        Text("مع بعض، العادة أحلى")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Theme.text)
                        Text("عادة واحدة، أنت وصديقك، ونجمة تطوّرونها سوا.")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.subtle)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                    NavigationLink {
                        StartHabitTogetherScreen()
                    } label: {
                        Text("ابدأ عادة مع صديق")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .background(Theme.pink, in: Capsule())
                    }
                    .padding(.top, 42)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("لكل عادة رحلتها")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.yellow)
                        Text("تقدرين تبدئين المذاكرة مع صديق آخر.\nكل رحلة لها عادة وجدول ورصيد مستقل.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.subtle)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .frame(minHeight: 137, alignment: .topLeading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 34)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppTabBar(selected: .friends)
            }
        }
    }
}

// MARK: - Tab bar

enum AppTab: CaseIterable {
    case home, habits, stars, friends
    var title: String {
        switch self {
        case .home: return "الرئيسية"
        case .habits: return "عاداتي"
        case .stars: return "نجمتي"
        case .friends: return "أصدقائي"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house"
        case .habits: return "list.bullet"
        case .stars: return "chart.line.uptrend.xyaxis"
        case .friends: return "sparkles"
        }
    }
}

struct AppTabBar: View {
    let selected: AppTab
    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(tab == selected ? Theme.pink : Theme.text)
                    Text(tab.title).font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(tab == selected ? Theme.purple : Color.clear,
                            in: Capsule())
            }
        }
        .padding(4)
        .background(Theme.cardSoft, in: Capsule())
        .overlay { Capsule().strokeBorder(Theme.subtle.opacity(0.35), lineWidth: 0.75) }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Screen 2: ابدؤوا عادة سوا

struct HabitOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct StartHabitTogetherScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options = [
        HabitOption(title: "المشي", subtitle: "من عاداتك · يوميًا · تُربط بدون تكرار"),
        HabitOption(title: "القراءة", subtitle: "من عاداتك · يوميًا")
    ]
    @State private var selectedID: UUID?
    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("ابدؤوا عادة سوا")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .accessibilityLabel("رجوع")
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.top, 12)
                    Text("وش العادة اللي تبغون\nتبدؤونها سوا؟")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .lineSpacing(6)
                        .padding(.top, 36)
                    Text("اختاري عادة واحدة")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.subtle)
                        .padding(.top, 32)
                        .padding(.bottom, 14)
                    VStack(spacing: 14) {
                        ForEach(options) { option in
                            HabitRow(option: option, isSelected: option.id == selectedID) {
                                selectedID = option.id
                            }
                        }
                    }
                    Button {
                        // TODO: present add-habit sheet
                    } label: {
                        Text("أضيفي عادة جديدة")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.text)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Theme.card.opacity(0.85), in: Capsule())
                    }
                    .padding(.top, 22)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    // TODO: continue
                } label: {
                    Text("المتابعة")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("ThemeOnAccent"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(selectedID == nil ? Theme.pink.opacity(0.55) : Theme.pink,
                                    in: Capsule())
                }
                .disabled(selectedID == nil)
                .padding(.bottom, 12)
                .padding(.horizontal, 20)
            }
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}

struct HabitRow: View {
    let option: HabitOption
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.system(size: 18, weight: .bold))
                    Text(option.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.subtle)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Theme.text, lineWidth: 1.5).frame(width: 28, height: 28)
                    if isSelected {
                        Circle().fill(Theme.pink).frame(width: 16, height: 16)
                    }
                }
                .padding(.leading, 8)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Theme.pink : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Root (right-to-left)

struct HabitsRootView: View {
    var body: some View {
        NavigationStack {
            FriendsScreen()
                #if os(iOS) || os(tvOS) || os(visionOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .preferredColorScheme(.dark)
    }
}

#Preview("الأصدقاء") {
    HabitsRootView()
}

#Preview("ابدؤوا عادة سوا") {
    NavigationStack {
        StartHabitTogetherScreen()
    }
    .environment(\.layoutDirection, .rightToLeft)
    .environment(\.locale, Locale(identifier: "ar"))
    .preferredColorScheme(.dark)
}
