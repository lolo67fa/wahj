import SwiftUI
import os

// اختيار النجمة المشتركة ثم إرسال الدعوة.
// المجموعات بنفس الأسماء والرسومات الموجودة في «اختار نجمتك» (StarProgress وConstellationDrawing).
struct FriendChooseStarView: View {
    let habitID: UUID
    // وش يصير بعد ما تنرسل الدعوة (يجي من FriendsTab)
    let onFinish: (String) -> Void

    @Environment(HabitStore.self) private var store
    @Environment(JourneyService.self) private var service
    @Environment(\.dismiss) private var dismiss

    @State private var selected = 0
    @State private var isWorking = false
    @State private var invite: InviteSummary?   // تفتح نافذة المشاركة لما تجهز
    @State private var journeyID: String?
    @State private var errorMessage: String?

    private var habit: Habit? { store.habits.first { $0.id == habitID } }

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 16) {
                HStack {
                    Text("اختار نجمتكم")
                        .font(.system(size: 22, weight: .bold))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("رجوع")
                }
                .foregroundStyle(AppTheme.text)
                .padding(.top, 8)

                if let habit {
                    Text("عادتكم: \(habit.name)")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(StarProgress.names.indices, id: \.self) { index in
                            FriendStarCard(index: index, isSelected: selected == index)
                                .onTapGesture { selected = index }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAddTraits(selected == index ? .isSelected : [])
                        }
                    }
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.hidden)

                // زر إرسال الدعوة: ينشئ الرحلة والدعوة ثم يفتح نافذة المشاركة
                Button(action: sendInvite) {
                    Group {
                        if isWorking {
                            ProgressView().tint(AppTheme.onAccent)
                        } else {
                            Text("التالي: إرسال الدعوة").bold()
                        }
                    }
                    .foregroundStyle(AppTheme.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppTheme.accent, in: Capsule())
                }
                .disabled(isWorking || habit == nil)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $invite, onDismiss: {
            if let journeyID { onFinish(journeyID) }
        }) { invite in
            ShareSheet(items: [InviteItem(invite: invite)]) { _ in
                self.invite = nil
            }
            .presentationDetents([.medium, .large])
        }
        .alert("تعذّر إرسال الدعوة", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func sendInvite() {
        journeyTrace("send invite tapped (habit found: \(habit != nil))")
        guard let habit else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                // لو العادة مشتركة من قبل نستخدم نفس الرحلة
                let id: String
                if let existing = habit.sharedJourneyID {
                    id = existing
                } else {
                    id = try await service.createJourney(for: habit, constellationIndex: selected)
                }
                journeyID = id
                invite = try await service.createInvite(for: id)
            } catch {
                journeyTrace("send invite failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

// بطاقة مجموعة: نفس خلفية ورسم بطاقات «اختار نجمتك».
struct FriendStarCard: View {
    let index: Int
    let isSelected: Bool

    var body: some View {
        ZStack {
            ConstellationCardBackground(seed: index)

            VStack(alignment: .leading, spacing: 8) {
                ConstellationDrawing(index: index, progress: 1, locked: false)
                    .frame(height: 110)
                    .padding(.horizontal, 24)

                HStack {
                    Text(StarProgress.names[index])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.onSky)
                    Spacer()
                    if isSelected {
                        Text("مختارة")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "33203F"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppTheme.onSkyAccent, in: Capsule())
                    }
                }
                Text("١٠٠ نقطة لكل مجموعة")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.onSkyAccent)
            }
            .padding(14)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isSelected ? AppTheme.onSkyAccent : AppTheme.onSkyAccent.opacity(0.12), lineWidth: isSelected ? 2 : 1)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    NavigationStack {
        FriendChooseStarView(habitID: UUID()) { _ in }
    }
    .environment(HabitStore.preview)
    .environment(JourneyService())
}
