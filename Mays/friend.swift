import SwiftUI

// صفحة الرحلة المشتركة: النجمة اللي نكملها سوا، الأعضاء وتقدمهم وستريكهم الحقيقي،
// والدعوات اللي ما انقبلت بعد.
struct FriendsListView: View {
    let state: JourneyState
    let allStates: [JourneyState]
    @Binding var selectedTab: Int
    var onSelectJourney: (String) -> Void = { _ in }
    var onStartNew: () -> Void = {}

    @Environment(JourneyService.self) private var service

    @State private var pendingInvites: [InviteSummary] = []
    @State private var shareInvite: InviteSummary?
    @State private var isInviting = false
    @State private var confirmLeave = false
    @State private var errorMessage: String?

    private var starName: String {
        StarProgress.names[min(max(state.journey.constellationIndex, 0), StarProgress.names.count - 1)]
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    starCard

                    Text("أصدقاؤك")
                        .font(.footnote.bold())
                        .foregroundStyle(AppTheme.textSecondary)

                    // صف لكل عضوة
                    ForEach(state.members) { member in
                        memberRow(member)
                    }

                    if !pendingInvites.isEmpty {
                        Text("دعوات ما انقبلت بعد")
                            .font(.footnote.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 4)
                        ForEach(pendingInvites) { invite in
                            inviteRow(invite)
                        }
                    }

                    // دعوة صديقة لنفس الرحلة
                    Button(action: inviteFriend) {
                        HStack {
                            if isInviting { ProgressView().tint(AppTheme.text) }
                            Text("+ دعوة صديق للانضمام").bold()
                        }
                        .foregroundStyle(AppTheme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(
                            // اطار منقط
                            Capsule().stroke(AppTheme.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                    .disabled(isInviting)
                    .padding(.top, 8)

                    // رحلة جديدة مع صديقة
                    Button(action: onStartNew) {
                        Text("ابدأ عادة مع صديق")
                            .bold()
                            .foregroundStyle(AppTheme.onAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.accent, in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomTabBar(selected: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        // الصفحة من اليمين لليسار
        .environment(\.layoutDirection, .rightToLeft)
        .task(id: state.id) { await loadInvites() }
        // نافذة المشاركة حقت ابل
        .sheet(item: $shareInvite, onDismiss: { Task { await loadInvites() } }) { invite in
            ShareSheet(items: [InviteItem(invite: invite)]) { _ in shareInvite = nil }
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("مغادرة الرحلة؟", isPresented: $confirmLeave, titleVisibility: .visible) {
            Button("مغادرة الرحلة", role: .destructive) {
                Task {
                    do { try await service.leave(state.id) } catch { errorMessage = error.localizedDescription }
                }
            }
        } message: {
            Text("تبقى إنجازاتك السابقة في الرحلة، وتبقى عادتك عندك بدون مشاركة.")
        }
        .alert("صار خطأ", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Parts

    private var header: some View {
        HStack {
            Text("الأصدقاء")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)
            Spacer()
            Menu {
                if allStates.count > 1 {
                    ForEach(allStates) { other in
                        Button(other.journey.habitTitle) { onSelectJourney(other.id) }
                    }
                    Divider()
                }
                Button("مغادرة الرحلة", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    confirmLeave = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("خيارات الرحلة")
        }
        .padding(.top, 12)
    }

    // بطاقة النجمة اللي نكملها سوا
    private var starCard: some View {
        ZStack {
            ConstellationCardBackground(seed: state.journey.constellationIndex)

            VStack(alignment: .leading, spacing: 8) {
                Text("نجمتنا سوا · \(starName)")
                    .font(.footnote.bold())
                    .foregroundStyle(AppTheme.onSky)

                ConstellationDrawing(
                    index: state.journey.constellationIndex,
                    progress: Double(state.points) / Double(HabitProgress.pointsPerConstellation),
                    locked: false,
                    lightsAlongPath: true
                )
                .frame(height: 120)
                .padding(.horizontal, 24)

                HStack {
                    Label(state.journey.habitTitle, systemImage: state.journey.habitIcon)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.onSkySecondary)
                    Spacer()
                    Text("\(arabicNumber(state.points)) / ١٠٠ نقطة")
                        .font(.footnote.bold())
                        .foregroundStyle(AppTheme.onSkyAccent)
                        .contentTransition(.numericText())
                }
            }
            .padding(16)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.accent.opacity(0.25), lineWidth: 1))
        .animation(.snappy, value: state.points)
        .accessibilityElement(children: .combine)
    }

    private func memberRow(_ member: JourneyMember) -> some View {
        let isMe = member.id == service.accountID
        return HStack(spacing: 10) {
            // اول حرف من الاسم داخل دائرة
            Text(String(member.displayName.prefix(1)))
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
                .frame(width: 36, height: 36)
                .background(AppTheme.background, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(isMe ? "\(member.displayName) (أنت)" : member.displayName)
                    .bold()
                    .foregroundStyle(AppTheme.text)
                Text(member.active
                     ? "مساهمة: \(arabicNumber(state.contribution(of: member.id))) نقطة"
                     : "غادر الرحلة")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            // الستريك الحقيقي من سجل إنجازاتها
            Text("🔥 \(arabicNumber(member.streak)) يوم")
                .font(.footnote.bold())
                .foregroundStyle(AppTheme.gold)
        }
        .padding(12)
        .background(AppTheme.surface, in: Capsule())
        .opacity(member.active ? 1 : 0.55)
        .accessibilityElement(children: .combine)
    }

    private func inviteRow(_ invite: InviteSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(InviteCode.formatted(invite.code))
                    .font(.caption.monospaced())
                    .foregroundStyle(AppTheme.text)
                    .environment(\.layoutDirection, .leftToRight)
                Text("تنتهي \(invite.expiresAt.formatted(.relative(presentation: .named).locale(Locale(identifier: "ar"))))")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Button("مشاركة") { shareInvite = invite }
                .font(.caption.bold())
                .foregroundStyle(AppTheme.accent)
            Button("إلغاء") {
                Task {
                    do {
                        try await service.revokeInvite(invite.code)
                        await loadInvites()
                    } catch { errorMessage = error.localizedDescription }
                }
            }
            .font(.caption.bold())
            .foregroundStyle(AppTheme.error)
            .padding(.leading, 8)
        }
        .padding(12)
        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func inviteFriend() {
        isInviting = true
        Task {
            defer { isInviting = false }
            do {
                shareInvite = try await service.createInvite(for: state.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadInvites() async {
        pendingInvites = (try? await service.activeInvites(for: state.id)) ?? []
    }
}
