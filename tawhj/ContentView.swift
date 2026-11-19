import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var showLogin = false
    @State private var signedIn = false
    @State private var checkingSession = true
    @State private var authListener: AuthStateDidChangeListenerHandle?

    // Firebase UID of the signed-in account; each account has its own data.
    @State private var accountID: String?
    @Environment(HabitStore.self) private var habitStore
    @Environment(JourneyService.self) private var journeyService

    private let secondaryText = AppTheme.textSecondary

    var body: some View {
        ZStack {
            if checkingSession {
                SpaceBackground()
                ProgressView()
                    .tint(AppTheme.text)
            } else if signedIn, let accountID {
                // كل الصفحات بعد الدخول تقرأ إعداداتها (الاسم، النجمة المختارة...)
                // من بيانات هذا الحساب فقط.
                SignedInRootView(accountID: accountID)
                    .defaultAppStorage(HabitStore.accountDefaults(for: accountID))
                    .id(accountID)
            } else {
                welcomeScreen
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showLogin) {
            EmailLoginView()
        }
        .onAppear {
            guard authListener == nil else { return }

            authListener = Auth.auth().addStateDidChangeListener {
                _, user in

                habitStore.activate(account: user?.uid)
                journeyService.activate(account: user?.uid, store: habitStore)
                accountID = user?.uid
                signedIn = user != nil
                checkingSession = false

                if user != nil {
                    showLogin = false
                }
            }
        }
        .onDisappear {
            if let authListener {
                Auth.auth().removeStateDidChangeListener(authListener)
                self.authListener = nil
            }
        }
    }

    private var welcomeScreen: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    StarOrbit()

                    AnimatedStar(
                        imageName: "starCharacter",
                        size: 183
                    )
                }

                Spacer()
                    .frame(height: 50)

                Text("نجوم")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        AppTheme.text
                    )

                Text("عاداتك اليومية تضوي نجمتك، نجمة بعد نجمة")
                    .font(.system(size: 14))
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                Button {
                    showLogin = true
                } label: {
                    Text("تسجيل الدخول")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            AppTheme.background
                        )
                        .frame(width: 280, height: 60)
                        .background(AppTheme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 48)

                Spacer()

                Text("بالمتابعة توافق على الشروط والخصوصية")
                    .font(.system(size: 11))
                    .foregroundStyle(secondaryText)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct EmailLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var creatingAccount = false
    @State private var isLoading = false
    @State private var message = ""
    @State private var showMessage = false

    private let pink = AppTheme.accent

    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        AnimatedStar(
                            imageName: "starCharacter",
                            size: 100
                        )
                        .padding(.top, 30)

                        Text(
                            creatingAccount
                            ? "ابدئي رحلتك معنا"
                            : "نورتي من جديد"
                        )
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.text)

                        Text(
                            creatingAccount
                            ? "أنشئي حسابك بالإيميل وكلمة المرور"
                            : "سجّلي دخولك بالإيميل وكلمة المرور"
                        )
                        .font(.system(size: 14))
                        .foregroundStyle(pink.opacity(0.85))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("البريد الإلكتروني")

                            TextField(
                                "name@example.com",
                                text: $email
                            )
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(
                                AppTheme.field,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .environment(
                                \.layoutDirection,
                                .leftToRight
                            )

                            Text("كلمة المرور")
                                .padding(.top, 8)

                            SecureField(
                                "كلمة المرور",
                                text: $password
                            )
                            .textContentType(
                                creatingAccount
                                ? .newPassword
                                : .password
                            )
                            .padding(16)
                            .background(
                                AppTheme.field,
                                in: RoundedRectangle(cornerRadius: 16)
                            )

                            if creatingAccount {
                                Text("تأكيد كلمة المرور")
                                    .padding(.top, 8)

                                SecureField(
                                    "أعيدي كتابة كلمة المرور",
                                    text: $confirmPassword
                                )
                                .textContentType(.newPassword)
                                .padding(16)
                                .background(
                                    AppTheme.field,
                                    in: RoundedRectangle(cornerRadius: 16)
                                )
                            }
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.text)
                        .disabled(isLoading)

                        if !creatingAccount {
                            Button("نسيتِ كلمة المرور؟") {
                                resetPassword()
                            }
                            .foregroundStyle(pink)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .trailing
                            )
                            .disabled(isLoading)
                        }

                        Button {
                            authenticate()
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(
                                            AppTheme.onAccent
                                        )
                                } else {
                                    Text(
                                        creatingAccount
                                        ? "إنشاء حساب"
                                        : "تسجيل الدخول"
                                    )
                                    .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(
                                AppTheme.onAccent
                            )
                            .background(pink, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            isLoading ||
                            cleanEmail.isEmpty ||
                            password.isEmpty ||
                            (
                                creatingAccount &&
                                confirmPassword.isEmpty
                            )
                        )
                        .opacity(
                            cleanEmail.isEmpty || password.isEmpty
                            ? 0.6
                            : 1
                        )

                        Button {
                            creatingAccount.toggle()
                            password = ""
                            confirmPassword = ""
                        } label: {
                            Text(
                                creatingAccount
                                ? "عندك حساب؟ سجّلي دخولك"
                                : "ما عندك حساب؟ أنشئي حسابًا"
                            )
                            .foregroundStyle(pink)
                        }
                        .disabled(isLoading)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(
                creatingAccount ? "إنشاء حساب" : "تسجيل الدخول"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundStyle(pink)
                    .disabled(isLoading)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(isLoading)
        .alert("تنبيه", isPresented: $showMessage) {
            Button("تمام", role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    private func authenticate() {
        if creatingAccount {
            guard password == confirmPassword else {
                displayMessage("كلمتا المرور غير متطابقتين.")
                return
            }

            guard password.count >= 6 else {
                displayMessage("اكتبي كلمة مرور من ٦ أحرف على الأقل.")
                return
            }
        }

        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }

            do {
                if creatingAccount {
                    _ = try await Auth.auth().createUser(
                        withEmail: cleanEmail,
                        password: password
                    )
                } else {
                    _ = try await Auth.auth().signIn(
                        withEmail: cleanEmail,
                        password: password
                    )
                }

                password = ""
                confirmPassword = ""
                dismiss()
            } catch {
                AuthErrorDiagnostics.log(error, operation: creatingAccount ? "createUser" : "signIn")
                displayMessage(authenticationMessage(for: error))
            }
        }
    }

    private func resetPassword() {
        guard !cleanEmail.isEmpty else {
            displayMessage("اكتبي بريدك الإلكتروني أولًا.")
            return
        }

        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }

            do {
                try await Auth.auth().sendPasswordReset(
                    withEmail: cleanEmail
                )

                displayMessage(
                    "إذا كان البريد مرتبطًا بحساب، بتوصلك رسالة لاستعادة كلمة المرور. شيّكي البريد غير المرغوب أيضًا."
                )
            } catch {
                AuthErrorDiagnostics.log(error, operation: "sendPasswordReset")
                displayMessage(authenticationMessage(for: error))
            }
        }
    }

    private func displayMessage(_ text: String) {
        message = text
        showMessage = true
    }

    private func authenticationMessage(for error: Error) -> String {
        switch (error as NSError).code {
        case AuthErrorCode.invalidEmail.rawValue:
            return "صيغة البريد الإلكتروني غير صحيحة."

        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "البريد مسجّل من قبل. اختاري تسجيل الدخول."

        case AuthErrorCode.weakPassword.rawValue:
            return "كلمة المرور ضعيفة. اختاري كلمة أطول وأقوى."

        case AuthErrorCode.wrongPassword.rawValue,
             AuthErrorCode.userNotFound.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            return "تعذّر الدخول. تأكدي من البريد وكلمة المرور."

        case AuthErrorCode.networkError.rawValue:
            return "تأكدي من اتصال الإنترنت وحاولي مرة ثانية."

        case AuthErrorCode.operationNotAllowed.rawValue:
            return "فعّلي Email/Password من إعدادات Authentication في Firebase."

        case AuthErrorCode.tooManyRequests.rawValue:
            return "المحاولات كثيرة. انتظري قليلًا وحاولي مرة ثانية."

        case AuthErrorCode.userDisabled.rawValue:
            return "هذا الحساب موقوف. تواصلي مع مسؤول التطبيق."

        default:
            return error.localizedDescription
        }
    }
}
