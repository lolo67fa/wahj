//
//  OnboardingView.swift
//  tawhj
//
//  Created by ghala alshreef on 05/06/1448 AH.
//

import SwiftUI

private enum IntroColors {
    static let text = AppTheme.text
    static let secondary = AppTheme.textSecondary
    static let pink = AppTheme.accent
    static let card = AppTheme.field
    static let purple = AppTheme.elevated
    static let darkCard = AppTheme.surface
    static let background = AppTheme.background
}

private enum IntroAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "حسب الجهاز"
        case .light: return "فاتح"
        case .dark: return "داكن"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "يتبع جوالك"
        case .light: return "نهاري"
        case .dark: return "ليلي"
        }
    }
}

struct OnboardingView: View {
    @AppStorage("selectedAppearance")
    private var appearance = "system"

    @AppStorage("displayName")
    private var savedName = ""

    @State private var name = ""
    @State private var showNamePage = false
    @State private var showSavedAlert = false
    @State private var showWelcome = false

    @FocusState private var nameFocused: Bool

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 0) {
                ScrollView {
                    if showNamePage {
                        namePage
                    } else {
                        appearancePage
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                footer
                    .padding(.top, 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 55)
        }
        .foregroundStyle(IntroColors.text)
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showWelcome) {
            WelcomeView()
        }
        .onAppear {
            name = savedName
        }
        .alert("تم حفظ اسمك", isPresented: $showSavedAlert) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text("يا هلا \(savedName)! نربط الشاشة التالية بعد تصميمها.")
        }
    }

    // MARK: - اختيار المظهر

    private var appearancePage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("قبل ما نبدأ")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(IntroColors.secondary)

            Text("وش يريح عينك؟")
                .font(.title.bold())

            HStack(alignment: .top, spacing: 14) {
                ForEach(IntroAppearance.allCases) { option in
                    appearanceOption(option)
                }
            }
            .padding(.top, 74)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
    }

    private func appearanceOption(
        _ option: IntroAppearance
    ) -> some View {
        Button {
            appearance = option.rawValue
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardColor(option))

                    VStack(alignment: .trailing, spacing: 12) {
                        Capsule()
                            .fill(detailColor(option))
                            .frame(width: 44, height: 6)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                option == .light
                                ? detailColor(option)
                                : IntroColors.purple
                            )
                            .frame(height: 60)

                        if option == .system {
                            ForEach(0..<3) { _ in
                                Capsule()
                                    .fill(IntroColors.darkCard)
                                    .frame(height: 14)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(10)

                    if appearance == option.rawValue {
                        Text("✓")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.text)
                            .frame(width: 22, height: 22)
                            .background(
                                IntroColors.pink,
                                in: Circle()
                            )
                            .padding(8)
                    }
                }
                .frame(height: 190)

                Text(option.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(option.subtitle)
                    .font(.caption)
            }
            .foregroundStyle(IntroColors.secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(
            appearance == option.rawValue ? [.isSelected] : []
        )
    }

    private func cardColor(_ option: IntroAppearance) -> Color {
        switch option {
        case .system:
            return IntroColors.purple
        case .light:
            return Color(red: 0.69, green: 0.66, blue: 0.72)
        case .dark:
            return IntroColors.darkCard
        }
    }

    private func detailColor(_ option: IntroAppearance) -> Color {
        option == .light
        ? Color(red: 0.64, green: 0.60, blue: 0.69)
        : IntroColors.darkCard
    }

    // MARK: - إدخال الاسم

    private var namePage: some View {
        VStack(spacing: 14) {
            ZStack {
                StarOrbit()
                    .scaleEffect(0.75)

                Image("starSleeping")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 175, height: 175)
            }
            .frame(height: 235)
            .accessibilityHidden(true)

            Text("وش حاب نناديك؟")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("نُجيمة بتناديك باسمك داخل التطبيق")
                .font(.subheadline)
                .foregroundStyle(IntroColors.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 10) {
                Text("اسمك")
                    .font(.subheadline.weight(.semibold))

                TextField("اكتب اسمك", text: $name)
                    .font(.body)
                    .foregroundStyle(IntroColors.secondary)
                    .multilineTextAlignment(.trailing)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .onSubmit {
                        nameFocused = false
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 56)
                    .background(
                        IntroColors.card,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .tint(IntroColors.pink)
            }
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 24)
    }

    // MARK: - زر المتابعة

    private var footer: some View {
        VStack(spacing: 16) {
            if !showNamePage {
                Text("«حسب الجهاز» يتبدّل تلقائيًا مع إعدادات جوالك")
                    .font(.caption)
                    .foregroundStyle(IntroColors.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if showNamePage {
                    nameFocused = false
                    savedName = cleanName
                    showWelcome = true                } else {
                    showNamePage = true
                }
            } label: {
                Text("متابعة")
                    .font(.headline)
                    .foregroundStyle(IntroColors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(IntroColors.pink, in: Capsule())
                    .shadow(
                        color: AppTheme.accentShadow,
                        radius: 0,
                        y: 5
                    )
            }
            .buttonStyle(.plain)
            .disabled(showNamePage && cleanName.isEmpty)
            .opacity(
                showNamePage && cleanName.isEmpty ? 0.5 : 1
            )
        }
    }
}

#Preview {
    OnboardingView()
}
