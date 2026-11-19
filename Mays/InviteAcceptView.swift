import SwiftUI

// تفتح لما توصلك دعوة (من الرابط أو من رمز الدعوة):
// اسم الداعية والعادة والمجموعة، ثم قبول أو رفض.
struct InviteAcceptView: View {
    let code: String
    var onJoined: (String) -> Void = { _ in }
    var onClose: () -> Void = {}

    @Environment(JourneyService.self) private var service

    private enum Phase: Equatable {
        case loading
        case lookup(InviteLookup)
        case joined(String)
        case failed(String)
    }

    @State private var phase: Phase = .loading
    @State private var isAccepting = false

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.surface, in: Circle())
                    }
                    .accessibilityLabel("إغلاق")
                }

                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            Spacer()
            ProgressView().tint(AppTheme.text)
            Text("نجيب تفاصيل الدعوة…")
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()

        case .lookup(.ready(let invite)):
            invitation(invite)

        case .lookup(.alreadyMember(let journeyId)):
            message(icon: "person.2.fill",
                    title: "أنتِ عضوة في هذه الرحلة",
                    detail: "ما يحتاج تنضمين مرة ثانية.",
                    action: ("افتحي الرحلة", { onJoined(journeyId) }))

        case .lookup(.expired):
            message(icon: "hourglass", title: "انتهت صلاحية الدعوة",
                    detail: "اطلبي من صديقتك دعوة جديدة.", action: nil)

        case .lookup(.revoked):
            message(icon: "xmark.circle", title: "أُلغيت هذه الدعوة",
                    detail: "صاحبة الدعوة ألغتها. اطلبي دعوة جديدة.", action: nil)

        case .lookup(.invalid):
            message(icon: "questionmark.circle", title: "الدعوة غير صحيحة",
                    detail: "تأكدي من الرابط أو رمز الدعوة.", action: nil)

        case .joined(let journeyId):
            message(icon: "sparkles", title: "انضممتِ للرحلة!",
                    detail: "العادة صارت ضمن عاداتك، وكل إنجاز يضيء نجمتكم المشتركة.",
                    action: ("افتحي الرحلة", { onJoined(journeyId) }))

        case .failed(let text):
            message(icon: "wifi.exclamationmark", title: "تعذّر فتح الدعوة",
                    detail: text, action: ("حاولي مرة ثانية", { Task { await load() } }))
        }
    }

    private func invitation(_ invite: InviteSummary) -> some View {
        VStack(spacing: 16) {
            AnimatedStar(imageName: "starWink", size: 110)

            Text("\(invite.inviterName) تدعوك لرحلة مشتركة")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.center)

            Label(invite.habitTitle, systemImage: invite.habitIcon)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)

            FriendStarCard(index: min(max(invite.constellationIndex, 0), StarProgress.names.count - 1),
                           isSelected: true)

            Text("كل إنجاز منكم يضيف ٥ نقاط للنجمة المشتركة، ونقاطك الشخصية تبقى لك.")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                accept(invite)
            } label: {
                Group {
                    if isAccepting { ProgressView().tint(AppTheme.onAccent) } else { Text("قبول الدعوة").bold() }
                }
                .foregroundStyle(AppTheme.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.accent, in: Capsule())
            }
            .disabled(isAccepting)

            Button("رفض", action: onClose)
                .foregroundStyle(AppTheme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.surface, in: Capsule())
                .disabled(isAccepting)
        }
    }

    private func message(icon: String, title: String, detail: String,
                         action: (String, () -> Void)?) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
            Text(detail)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            if let action {
                Button(action: action.1) {
                    Text(action.0).bold()
                        .foregroundStyle(AppTheme.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.accent, in: Capsule())
                }
            }
            Button("إغلاق", action: onClose)
                .foregroundStyle(AppTheme.text)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.surface, in: Capsule())
        }
    }

    // MARK: - Actions

    private func load() async {
        phase = .loading
        do {
            phase = .lookup(try await service.lookup(code))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func accept(_ invite: InviteSummary) {
        isAccepting = true
        Task {
            defer { isAccepting = false }
            do {
                switch try await service.accept(invite) {
                case .joined(let journeyId): phase = .joined(journeyId)
                case .alreadyMember(let journeyId): phase = .lookup(.alreadyMember(journeyId: journeyId))
                case .expired: phase = .lookup(.expired)
                case .revoked: phase = .lookup(.revoked)
                case .invalid: phase = .lookup(.invalid)
                }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

// لو الرابط ما فتح التطبيق: الصقي أو اكتبي رمز الدعوة هنا.
struct InviteCodeEntryView: View {
    var onJoined: (String) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var code: String?

    var body: some View {
        if let code {
            InviteAcceptView(code: code, onJoined: { id in
                dismiss()
                onJoined(id)
            }, onClose: { dismiss() })
        } else {
            ZStack {
                SpaceBackground()
                VStack(alignment: .leading, spacing: 14) {
                    Text("رمز الدعوة")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text)
                    Text("الصقي الرمز اللي وصلك في رسالة الدعوة.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)

                    TextField("XXXXX-XXXXX-XXXXX-XXXXX", text: $text)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .foregroundStyle(AppTheme.text)
                        .padding(16)
                        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
                        .environment(\.layoutDirection, .leftToRight)

                    if !text.isEmpty && InviteCode.normalize(text) == nil {
                        Text("الرمز ٢٠ حرفًا ورقمًا.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.error)
                    }

                    Button {
                        code = InviteCode.normalize(text)
                    } label: {
                        Text("متابعة").bold()
                            .foregroundStyle(AppTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.accent, in: Capsule())
                    }
                    .disabled(InviteCode.normalize(text) == nil)
                    .opacity(InviteCode.normalize(text) == nil ? AppTheme.disabledOpacity : 1)

                    Spacer()
                }
                .padding(24)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
    }
}
