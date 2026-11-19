//
//  AccountMenu.swift
//  tawhj
//
//  The account menu (top of the home page) with a real Firebase sign-out.
//  Signing out only ends the session: the account's habits, points and
//  progress stay saved on this device and come back on the next sign-in.
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

struct AccountMenuButton: View {
    @AppStorage("displayName") private var displayName = ""

    @State private var isConfirming = false
    @State private var errorMessage: String?

    var body: some View {
        Menu {
            Section(displayName.isEmpty ? "حسابي" : displayName) {
                Button("تسجيل الخروج", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    isConfirming = true
                }
            }
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface, in: Circle())
                .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
        }
        .accessibilityLabel("الحساب")
        .accessibilityHint("فيه تسجيل الخروج")
        .confirmationDialog("تسجيل الخروج؟", isPresented: $isConfirming, titleVisibility: .visible) {
            Button("تسجيل الخروج", role: .destructive, action: signOut)
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("عاداتك ونقاطك تبقى محفوظة، وترجع لما تسجّلين دخولك مرة ثانية.")
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
            errorMessage = "ما قدرنا نسجّل خروجك. تأكدي من الاتصال وحاولي مرة ثانية."
        }
    }
}
