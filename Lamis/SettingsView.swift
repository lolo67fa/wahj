import SwiftUI

// Settings: appearance (same 3 options as Ghala's first-time page) and a few general rows.
// The appearance is saved with @AppStorage("appearance"); MyApp applies it to the whole app.
struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system
    @Environment(\.openURL) private var openURL

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                // Appearance
                section(title: "المظهر") {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            ForEach(Appearance.allCases, id: \.self) { option in
                                AppearanceCard(option: option, isSelected: appearance == option) {
                                    appearance = option
                                }
                            }
                        }
                        Text("«حسب الجهاز» يتبدل تلقائياً مع إعدادات جوالك")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.6))
                    }
                }

                // General
                section(title: "عام") {
                    VStack(spacing: 0) {
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            row(icon: "bell", title: "الإشعارات") {
                                Image(systemName: "chevron.left")
                                    .font(.footnote.bold())
                                    .foregroundStyle(Theme.text.opacity(0.4))
                            }
                        }
                        .buttonStyle(.plain)

                        Divider().overlay(Theme.border)

                        row(icon: "info.circle", title: "عن وهج") {
                            Text("الإصدار \(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(Theme.text.opacity(0.6))
                        }
                    }
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background { StarryBackground() }
        .environment(\.layoutDirection, .rightToLeft)
        .animation(.snappy, value: appearance)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("الإعدادات")
                .font(.largeTitle).bold()
                .foregroundStyle(Theme.text)
            Spacer()
            Image("app icon?")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
        }
    }

    // A titled group inside a rounded card.
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.text)
            content()
                .padding(14)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.border, lineWidth: 1))
        }
    }

    private func row<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.pink)
                .frame(width: 32, height: 32)
                .background(Theme.pink.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.body)
                .foregroundStyle(Theme.text)
            Spacer()
            trailing()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// One appearance choice: a small phone with a mini habit card, a title and a subtitle.
private struct AppearanceCard: View {
    let option: Appearance
    let isSelected: Bool
    let action: () -> Void

    private var subtitle: String {
        switch option {
        case .system: "يتبع جوالك"
        case .light:  "نهاري"
        case .dark:   "ليلي"
        }
    }

    // The drawing always shows the mode it stands for (not the current mode).
    private struct Palette { let screen, card, line, accent: Color }
    private let darkPalette = Palette(screen: Color(hex: "2F2240"), card: Color(hex: "3F2B55"),
                                      line: Color(hex: "5A3F73"), accent: Color(hex: "E6B4E1"))
    private let lightPalette = Palette(screen: Color(hex: "FAF0FB"), card: Color(hex: "F4E3F6"),
                                       line: Color(hex: "DDBFE2"), accent: Color(hex: "A0448F"))

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                phoneDrawing
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Theme.pink : Theme.border, lineWidth: isSelected ? 2.5 : 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.onAccent, Theme.pink)
                                .padding(6)
                        }
                    }
                    .scaleEffect(isSelected ? 1 : 0.96)

                Text(option.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.text.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var phoneDrawing: some View {
        switch option {
        case .dark:
            miniScreen(darkPalette, icon: "moon.fill")
        case .light:
            miniScreen(lightPalette, icon: "sun.max.fill")
        case .system:
            // Half light, half dark.
            HStack(spacing: 0) {
                miniScreen(lightPalette, icon: "sun.max.fill")
                miniScreen(darkPalette, icon: "moon.fill")
            }
        }
    }

    private func miniScreen(_ p: Palette, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(p.accent)
            // Two tiny habit cards
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 4) {
                    Circle().stroke(p.accent, lineWidth: 1.5).frame(width: 10, height: 10)
                    Capsule().fill(p.line).frame(height: 5)
                }
                .padding(5)
                .background(p.card, in: RoundedRectangle(cornerRadius: 6))
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(p.screen)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
