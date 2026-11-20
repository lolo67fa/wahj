//
//  SignedInRootView.swift
//  tawhj
//
//  What a signed-in account sees: onboarding the first time, then the tabs.
//  Its @AppStorage values come from that account's own defaults (set by ContentView).
//

import SwiftUI

struct SignedInRootView: View {
    let accountID: String

    @Environment(HabitStore.self) private var store

    // تتفعّل بعد إضافة أول عادة من صفحات البداية.
    @AppStorage("hasCompletedOnboarding")
    private var hasCompletedOnboarding = false

    @State private var showLegacyQuestion = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            showLegacyQuestion = LegacyHabitMigration.hasUnclaimedData(
                for: HabitStore.accountDefaults(for: accountID)
            )
        }
        // بيانات محفوظة على الجهاز قبل فصل الحسابات: ما نضيفها لأي حساب بدون موافقة.
        .alert("عادات محفوظة على هذا الجهاز", isPresented: $showLegacyQuestion) {
            Button("أضفها لحسابي") {
                LegacyHabitMigration.claim(
                    accountID: accountID,
                    account: HabitStore.accountDefaults(for: accountID),
                    into: store
                )
            }
            Button("لا، ابدأ من جديد", role: .cancel) {
                LegacyHabitMigration.decline(account: HabitStore.accountDefaults(for: accountID))
            }
        } message: {
            Text("وجدنا عادات حُفظت على هذا الجهاز قبل تسجيل الدخول. تبي تضيفها لحسابك؟ تبقى محفوظة على الجهاز في الحالتين.")
        }
    }
}
