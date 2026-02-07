import SwiftUI
import AuthenticationServices

// MARK: - Auth Mode

private enum AuthMode {
    case phone, email
}

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService

    // Auth mode
    @State private var authMode: AuthMode = .phone

    // Email state
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showingForgotPassword = false
    @State private var forgotPasswordEmail = ""

    // Phone/OTP state
    @State private var phoneNumber = ""
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var verificationID: String?
    @State private var showingOTPVerification = false
    @FocusState private var focusedOTPField: Int?

    // Legal sheets
    @State private var showingTerms = false
    @State private var showingPrivacy = false

    // Toast state
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isSuccessToast = false

    private var otpCode: String {
        otpDigits.joined()
    }

    private var formattedPhoneNumber: String {
        guard phoneNumber.count == 10 else { return phoneNumber }
        let part1 = phoneNumber.prefix(5)
        let part2 = phoneNumber.suffix(5)
        return "\(part1) \(part2)"
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: showingOTPVerification ? 16 : 40)

                    // Back button during OTP verification
                    if showingOTPVerification {
                        HStack {
                            Button {
                                withAnimation {
                                    showingOTPVerification = false
                                    otpDigits = Array(repeating: "", count: 6)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(Theme.Typography.subheadlineSemibold)
                                }
                                .foregroundColor(.primaryPurple)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    }

                    // App branding (hidden during OTP verification)
                    if !showingOTPVerification {
                        VStack(spacing: 16) {
                            ALLogoView(size: 70, color: .white)

                            Text("AUTO LEDGER")
                                .font(.system(size: 22, weight: .bold))
                                .tracking(3)
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.bottom, 24)
                    }

                    // Welcome text
                    VStack(spacing: 8) {
                        Text(welcomeTitle)
                            .font(Theme.Typography.title)
                            .foregroundColor(.textPrimary)

                        Text(welcomeSubtitle)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 32)

                    // Auth form based on mode
                    switch authMode {
                    case .phone:
                        phoneAuthSection
                    case .email:
                        emailAuthSection
                    }

                    // Or divider + social buttons + mode toggle (hidden during OTP)
                    if !showingOTPVerification {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(height: 1)
                            Text("Or Continue With")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                                .fixedSize()
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)

                        // Social sign-in buttons
                        HStack(spacing: 16) {
                            // Google
                            Button {
                                Task {
                                    await authService.signInWithGoogle()
                                    checkForError()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                    Text("Google")
                                        .font(Theme.Typography.subheadlineSemibold)
                                }
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                            }

                            // Apple
                            ZStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "apple.logo")
                                        .font(Theme.Typography.iconTiny)
                                    Text("Apple")
                                        .font(Theme.Typography.subheadlineSemibold)
                                }
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                                .allowsHitTesting(false)

                                SignInWithAppleButton(.signIn) { request in
                                    authService.handleSignInWithAppleRequest(request)
                                } onCompletion: { result in
                                    authService.handleSignInWithAppleCompletion(result)
                                    checkForError()
                                }
                                .signInWithAppleButtonStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .cornerRadius(12)
                                .opacity(0.015)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Mode toggle button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                switch authMode {
                                case .phone:
                                    authMode = .email
                                    phoneNumber = ""
                                    otpDigits = Array(repeating: "", count: 6)
                                    verificationID = nil
                                    showingOTPVerification = false
                                case .email:
                                    authMode = .phone
                                    email = ""
                                    password = ""
                                    confirmPassword = ""
                                    name = ""
                                    isSignUp = false
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: authMode == .phone ? "envelope.fill" : "phone.fill")
                                    .font(Theme.Typography.iconTiny)
                                Text(authMode == .phone ? "Continue with Email" : "Continue with Phone")
                                    .font(Theme.Typography.subheadlineSemibold)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }

                    Spacer().frame(height: 40)

                    // Terms footer
                    VStack(spacing: 4) {
                        Text("By Continuing, you Agree to our")
                            .foregroundColor(.textSecondary.opacity(0.6))
                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                showingTerms = true
                            }
                            .foregroundColor(.primaryPurple)
                            Text("and")
                                .foregroundColor(.textSecondary.opacity(0.6))
                            Button("Privacy Policy") {
                                showingPrivacy = true
                            }
                            .foregroundColor(.primaryPurple)
                        }
                    }
                    .font(Theme.Typography.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }

            // Toast notification
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()

                    HStack(spacing: 10) {
                        Image(systemName: isSuccessToast ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSuccessToast ? .greenAccent : .pinkAccent)

                        Text(message)
                            .font(Theme.Typography.subheadlineMedium)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSuccessToast ? Color.greenAccent.opacity(0.4) : Color.pinkAccent.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: showToast)
            }

            // Loading overlay
            if authService.isLoading {
                CarLoadingOverlay(message: "Please Wait...")
            }
        }
        .alert("Reset Password", isPresented: $showingForgotPassword) {
            TextField("Email", text: $forgotPasswordEmail)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            Button("Send Reset Link") {
                Task {
                    let success = await authService.resetPassword(email: forgotPasswordEmail)
                    if success {
                        showToastMessage("Password Reset Email Sent!", isSuccess: true)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .onChange(of: authService.errorMessage) { _, newValue in
            if let error = newValue {
                showToastMessage(error)
                authService.errorMessage = nil
            }
        }
        .sheet(isPresented: $showingTerms) {
            LegalDocumentView(title: "Terms of Service", fileName: "TERMS_OF_SERVICE")
        }
        .sheet(isPresented: $showingPrivacy) {
            LegalDocumentView(title: "Privacy Policy", fileName: "PRIVACY_POLICY")
        }
    }

    // MARK: - Welcome Text

    private var welcomeTitle: String {
        switch authMode {
        case .phone:
            return showingOTPVerification ? "Verify your Number" : "Welcome!"
        case .email:
            return isSignUp ? "Create Account" : "Welcome Back!"
        }
    }

    private var welcomeSubtitle: String {
        switch authMode {
        case .phone:
            return showingOTPVerification ? "Enter the Code Sent to your Phone" : "Continue with your Phone Number"
        case .email:
            return isSignUp ? "Sign Up to Get Started" : "Sign In to Continue"
        }
    }

    // MARK: - Phone Auth Section

    @ViewBuilder
    private var phoneAuthSection: some View {
        if !showingOTPVerification {
            phoneInputSection
        } else {
            otpVerificationSection
        }
    }

    private var phoneInputSection: some View {
        VStack(spacing: 16) {
            // Phone input — unified field with inline +91 prefix
            HStack(spacing: 0) {
                Text("+91")
                    .foregroundColor(.textSecondary)
                    .font(Theme.Typography.bodyMedium)
                    .padding(.leading, 16)

                Rectangle()
                    .fill(Color.textSecondary.opacity(0.3))
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, 12)

                TextField("", text: $phoneNumber, prompt: Text("Phone Number").foregroundColor(.textSecondary.opacity(0.5)))
                    .keyboardType(.phonePad)
                    .foregroundColor(.textPrimary)
                    .font(Theme.Typography.bodyMedium)
                    .padding(.trailing, 16)
                    .onChange(of: phoneNumber) { _, newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > 10 {
                            phoneNumber = String(filtered.prefix(10))
                        } else if filtered != newValue {
                            phoneNumber = filtered
                        }
                    }
            }
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            // Send OTP button
            Button {
                Task {
                    let fullNumber = "+91\(phoneNumber)"
                    if let id = await authService.sendVerificationCode(to: fullNumber) {
                        verificationID = id
                        withAnimation {
                            showingOTPVerification = true
                        }
                        focusedOTPField = 0
                    } else if let error = authService.errorMessage {
                        showToastMessage(error)
                        authService.errorMessage = nil
                    }
                }
            } label: {
                Text("Send OTP")
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(phoneNumber.count == 10 ? 1 : 0.5)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.primaryPurple.opacity(phoneNumber.count == 10 ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(phoneNumber.count != 10)
            .padding(.horizontal, 24)
        }
    }

    private var otpVerificationSection: some View {
        VStack(spacing: 24) {
            // Shield icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.greenAccent.opacity(0.3), Color.primaryPurple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.greenAccent)
            }

            // Phone number display with edit
            HStack(spacing: 4) {
                Text("+91 \(formattedPhoneNumber)")
                    .font(Theme.Typography.title3)
                    .foregroundColor(.primaryPurple)

                Button {
                    withAnimation {
                        showingOTPVerification = false
                        otpDigits = Array(repeating: "", count: 6)
                    }
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.primaryPurple)
                        .font(Theme.Typography.subheadline)
                }
            }

            // OTP Boxes
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    OTPDigitBox(
                        digit: $otpDigits[index],
                        isFocused: focusedOTPField == index
                    )
                    .focused($focusedOTPField, equals: index)
                    .onChange(of: otpDigits[index]) { oldValue, newValue in
                        handleOTPInput(index: index, oldValue: oldValue, newValue: newValue)
                    }
                }
            }
            .padding(.horizontal, 24)

            // Verify button
            Button {
                Task {
                    if let id = verificationID {
                        await authService.verifyCode(otpCode, verificationID: id)
                        if !authService.isAuthenticated, let error = authService.errorMessage {
                            showToastMessage(error)
                            authService.errorMessage = nil
                        }
                    }
                }
            } label: {
                Text("Verify & Continue")
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(otpCode.count == 6 ? 1 : 0.5)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.primaryPurple.opacity(otpCode.count == 6 ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(otpCode.count != 6)
            .padding(.horizontal, 24)

            // Resend link
            Button {
                Task {
                    let fullNumber = "+91\(phoneNumber)"
                    if let id = await authService.sendVerificationCode(to: fullNumber) {
                        verificationID = id
                        showToastMessage("OTP Sent Successfully!", isSuccess: true)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    Text("Didn't Receive Code? ")
                        .foregroundColor(.textSecondary)
                    Text("Resend")
                        .foregroundColor(.primaryPurple)
                        .fontWeight(.semibold)
                }
                .font(Theme.Typography.subheadline)
            }
        }
    }

    // MARK: - Email Auth Section

    private var emailAuthSection: some View {
        VStack(spacing: 16) {
            // Name field (Sign Up only)
            if isSignUp {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    TextField("", text: $name, prompt: Text("Full Name").foregroundColor(.textSecondary.opacity(0.7)))
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }

            // Email field
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.textSecondary)
                    .frame(width: 20)

                TextField("", text: $email, prompt: Text("Email").foregroundColor(.textSecondary.opacity(0.7)))
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )

            // Password field
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.textSecondary)
                    .frame(width: 20)

                Group {
                    if showPassword {
                        TextField("", text: $password, prompt: Text("Password").foregroundColor(.textSecondary.opacity(0.7)))
                    } else {
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.textSecondary.opacity(0.7)))
                    }
                }
                .textContentType(isSignUp ? .newPassword : .password)
                .foregroundColor(.textPrimary)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
            )

            // Confirm password for sign up
            if isSignUp {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.textSecondary)
                        .frame(width: 20)

                    SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.textSecondary.opacity(0.7)))
                        .textContentType(.newPassword)
                        .foregroundColor(.textPrimary)

                    if !confirmPassword.isEmpty {
                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password == confirmPassword ? .greenAccent : .red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
            }

            // Forgot password
            if !isSignUp {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        forgotPasswordEmail = email
                        showingForgotPassword = true
                    }
                    .font(Theme.Typography.subheadlineMedium)
                    .foregroundColor(.primaryPurple)
                }
                .padding(.top, 4)
            }

            // Sign In/Up button
            Button {
                Task {
                    if isSignUp {
                        await authService.signUp(email: email, password: password, name: name)
                    } else {
                        await authService.signIn(email: email, password: password)
                    }
                }
            } label: {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(isEmailFormValid ? 1 : 0.5)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.primaryPurple.opacity(isEmailFormValid ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(!isEmailFormValid)

            // Toggle sign in/up
            HStack(spacing: 4) {
                Text(isSignUp ? "Already Have an Account?" : "Don't Have an Account?")
                    .foregroundColor(.textSecondary)
                Button(isSignUp ? "Sign In" : "Sign Up") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignUp.toggle()
                        password = ""
                        confirmPassword = ""
                        name = ""
                    }
                }
                .foregroundColor(.primaryPurple)
                .fontWeight(.semibold)
            }
            .font(Theme.Typography.subheadline)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Form Validation

    private var isEmailFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    // MARK: - OTP Input Handler

    private func handleOTPInput(index: Int, oldValue: String, newValue: String) {
        let filtered = newValue.filter { $0.isNumber }

        if filtered.count > 1 {
            // Handle paste - distribute digits across boxes
            let digits = Array(filtered.prefix(6 - index))
            for (i, digit) in digits.enumerated() {
                if index + i < 6 {
                    otpDigits[index + i] = String(digit)
                }
            }
            if index + digits.count >= 6 {
                focusedOTPField = nil
            } else {
                focusedOTPField = min(index + digits.count, 5)
            }
        } else if filtered.count == 1 {
            otpDigits[index] = filtered
            if index < 5 {
                focusedOTPField = index + 1
            } else {
                focusedOTPField = nil
            }
        } else if filtered.isEmpty && !oldValue.isEmpty {
            otpDigits[index] = ""
            if index > 0 {
                focusedOTPField = index - 1
            }
        }
    }

    // MARK: - Helpers

    private func checkForError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let error = authService.errorMessage {
                showToastMessage(error)
                authService.errorMessage = nil
            }
        }
    }

    private func showToastMessage(_ message: String, isSuccess: Bool = false) {
        toastMessage = message
        isSuccessToast = isSuccess
        withAnimation {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showToast = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                toastMessage = nil
            }
        }
    }
}

// MARK: - OTP Digit Box

struct OTPDigitBox: View {
    @Binding var digit: String
    var isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.primaryPurple : Color.textSecondary.opacity(0.2), lineWidth: isFocused ? 2 : 1)
                )

            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(Theme.Typography.statValueSmall)
                .foregroundColor(.textPrimary)
        }
        .frame(width: 50, height: 56)
    }
}

// MARK: - Legal Document View

struct LegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let fileName: String

    private struct DocLine: Identifiable {
        let id: Int
        let text: AttributedString
        let isHeading: Bool
        let headingLevel: Int
    }

    @State private var lines: [DocLine] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(lines) { line in
                        if line.isHeading {
                            Text(line.text)
                                .font(line.headingLevel == 1 ? Theme.Typography.title2 : line.headingLevel == 2 ? Theme.Typography.title3 : Theme.Typography.headline)
                                .foregroundColor(.textPrimary)
                                .padding(.top, line.headingLevel <= 2 ? 16 : 8)
                        } else {
                            Text(line.text)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.darkBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
        }
        .onAppear {
            lines = Self.parseMarkdown(fileName: fileName)
        }
    }

    private static func parseMarkdown(fileName: String) -> [DocLine] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "md"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return [DocLine(id: 0, text: AttributedString("Document not available."), isHeading: false, headingLevel: 0)]
        }

        var results: [DocLine] = []
        var index = 0

        for line in raw.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "---" || trimmed.contains("|---") || trimmed.contains("| ---") || trimmed.isEmpty { continue }

            var headingLevel = 0
            var content = line
            if content.hasPrefix("#") {
                while content.hasPrefix("#") {
                    headingLevel += 1
                    content = String(content.dropFirst())
                }
                content = content.trimmingCharacters(in: .whitespaces)
            }

            if content.hasPrefix("|") {
                content = content.replacingOccurrences(of: "|", with: "  ").trimmingCharacters(in: .whitespaces)
            }

            let attributed = (try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(content)
            results.append(DocLine(id: index, text: attributed, isHeading: headingLevel > 0, headingLevel: headingLevel))
            index += 1
        }

        return results
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService())
}
