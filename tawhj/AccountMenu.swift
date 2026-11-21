//
//  AccountMenu.swift
//  tawhj
//
//  Settings entry on the home page, and the real Firebase sign-out shown in
//  Settings → الحساب. Signing out only ends the session: the account's
//  habits, points and progress stay saved on this device and come back on
//  the next sign-in.
//

import SwiftUI
import FirebaseAuth

enum AccountSession {
    // Ends the Firebase session. ContentView's auth listener then clears the
    // account from memory, stops its listeners and shows the sign-in screen.
    static func signOut() throws {
        try Auth.auth().signOut()
    }
}

// Gear button on the home page that opens Lamis's Settings page.
struct SettingsButton: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(Theme.pink)
                .frame(width: 44, height: 44)
                .background(Theme.card, in: Circle())
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
        }
        .accessibilityLabel("الإعدادات")
    }
}

// The account section in Settings: the name and «تسجيل الخروج».
struct AccountSection: View {
    @AppStorage("displayName") private var displayName = ""

    @State private var isConfirming = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if !displayName.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(Theme.pink)
                        .frame(width: 32, height: 32)
                        .background(Theme.pink.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Text(displayName)
                        .foregroundStyle(Theme.text)
                    Spacer()
                }
                .padding(.vertical, 10)

                Divider().overlay(Theme.border)
            }

            Button { isConfirming = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(AppTheme.error)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.error.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Text("تسجيل الخروج")
                        .foregroundStyle(AppTheme.error)
                    Spacer()
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("عاداتك ونقاطك تبقى محفوظة")
        }
        .confirmationDialog("تسجيل الخروج؟", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("تسجيل الخروج", role: .destructive, action: signOut)
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("عاداتك ونقاطك تبقى محفوظة، وترجع لما تسجّل دخولك مرة ثانية.")
        }
        .alert("تعذّر تسجيل الخروج", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func signOut() {
        do {
            try AccountSession.signOut()
        } catch {
            // Still signed in: nothing is cleared and the user stays where they are.
            AuthErrorDiagnostics.log(error, operation: "signOut")
            errorMessage = "ما قدرنا نسجّل خروجك. تأكد من الاتصال وحاول مرة ثانية."
        }
    }
}
