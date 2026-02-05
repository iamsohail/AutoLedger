import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var showingPhoneAuth = false
    @State private var toastMessage: String?
    @State private var showToast = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Welcome text
                    VStack(spacing: 8) {
                        Text(isSignUp ? "Create Account" : "Welcome Back!")
                            .font(Theme.Typography.title)
                            .foregroundColor(.textPrimary)

                        Text(isSignUp ? "Sign up to get started" : "Sign in to continue")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.bottom, 40)

                    // Form fields
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

                        // Remember me & Forgot password
                        if !isSignUp {
                            HStack {
                                Button {
                                    rememberMe.toggle()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                            .foregroundColor(rememberMe ? .primaryPurple : .textSecondary)
                                        Text("Remember Me")
                                            .font(Theme.Typography.subheadline)
                                            .foregroundColor(.textSecondary)
                                    }
                                }

                                Spacer()

                                Button("Forgot Password?") {
                                    // Handle forgot password
                                }
                                .font(Theme.Typography.subheadlineMedium)
                                .foregroundColor(.primaryPurple)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 24)

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
                                .opacity(isFormValid ? 1 : 0.5)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.primaryPurple.opacity(isFormValid ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Or divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("Or Continue with")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)
                            .fixedSize()
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                    // Social sign-in buttons - side by side
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
                                    .frame(width: 22, height: 22)
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
                        Button {
                            // Handled by overlay
                        } label: {
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
                        }
                        .overlay {
                            SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                                authService.handleSignInWithAppleRequest(request)
                            } onCompletion: { result in
                                authService.handleSignInWithAppleCompletion(result)
                                checkForError()
                            }
                            .blendMode(.overlay)
                            .opacity(0.02)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Phone sign in
                    Button {
                        showingPhoneAuth = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(Theme.Typography.body)
                            Text("Continue with Phone")
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

                    Spacer().frame(height: 40)

                    // Toggle sign in/up
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
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
                    .padding(.bottom, 30)
                }
            }

            // Toast notification
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()

                    Text(message)
                        .font(Theme.Typography.subheadlineMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3), value: showToast)
            }

            // Loading overlay
            if authService.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Please Wait...")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(Color.cardBackground)
                .cornerRadius(16)
            }
        }
        .sheet(isPresented: $showingPhoneAuth) {
            PhoneAuthView(authService: authService)
        }
        .onChange(of: authService.errorMessage) { _, newValue in
            if let error = newValue {
                showToastMessage(error)
                authService.errorMessage = nil
            }
        }
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func checkForError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let error = authService.errorMessage {
                showToastMessage(error)
                authService.errorMessage = nil
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
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

struct PhoneAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService: AuthenticationService
    @State private var phoneNumber = ""
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var verificationID: String?
    @State private var showingVerification = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @FocusState private var focusedField: Int?

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
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if !showingVerification {
                        // Phone input screen
                        VStack(spacing: 32) {
                            VStack(spacing: 8) {
                                Text("Enter Your Phone Number")
                                    .font(Theme.Typography.title2)
                                    .foregroundColor(.textPrimary)

                                Text("We'll Send You a Verification Code")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.top, 40)

                            // Phone input
                            HStack(spacing: 12) {
                                Text("+91")
                                    .foregroundColor(.textPrimary)
                                    .font(Theme.Typography.bodyMedium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 16)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)

                                TextField("", text: $phoneNumber, prompt: Text("Phone number").foregroundColor(.textSecondary.opacity(0.5)))
                                    .keyboardType(.phonePad)
                                    .foregroundColor(.textPrimary)
                                    .font(Theme.Typography.bodyMedium)
                                    .padding()
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)

                            Button {
                                Task {
                                    let fullNumber = "+91\(phoneNumber)"
                                    if let id = await authService.sendVerificationCode(to: fullNumber) {
                                        verificationID = id
                                        withAnimation {
                                            showingVerification = true
                                        }
                                        focusedField = 0
                                    } else if let error = authService.errorMessage {
                                        showToastMessage(error)
                                        authService.errorMessage = nil
                                    }
                                }
                            } label: {
                                Text("Send OTP")
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.primaryPurple, Color.pinkAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .opacity(phoneNumber.count >= 10 ? 1 : 0.5)
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(phoneNumber.count < 10)
                            .padding(.horizontal, 24)

                            Spacer()
                        }

                    } else {
                        // OTP Verification screen
                        VStack(spacing: 32) {
                            // Icon
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
                                    .font(Theme.Typography.statValueSmall)
                                    .foregroundColor(.greenAccent)
                            }
                            .padding(.top, 40)

                            VStack(spacing: 8) {
                                Text("Verify Your Number")
                                    .font(Theme.Typography.title2)
                                    .foregroundColor(.textPrimary)

                                Text("Enter the 6-Digit Code Sent to")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(.textSecondary)

                                HStack(spacing: 4) {
                                    Text("+91 \(formattedPhoneNumber)")
                                        .font(Theme.Typography.subheadlineSemibold)
                                        .foregroundColor(.primaryPurple)

                                    Button {
                                        withAnimation {
                                            showingVerification = false
                                            otpDigits = Array(repeating: "", count: 6)
                                        }
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.primaryPurple)
                                            .font(Theme.Typography.subheadline)
                                    }
                                }
                            }

                            // OTP Boxes
                            HStack(spacing: 10) {
                                ForEach(0..<6, id: \.self) { index in
                                    OTPDigitBox(
                                        digit: $otpDigits[index],
                                        isFocused: focusedField == index
                                    )
                                    .focused($focusedField, equals: index)
                                    .onChange(of: otpDigits[index]) { oldValue, newValue in
                                        handleOTPInput(index: index, oldValue: oldValue, newValue: newValue)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)

                            Button {
                                Task {
                                    if let id = verificationID {
                                        await authService.verifyCode(otpCode, verificationID: id)
                                        if authService.isAuthenticated {
                                            dismiss()
                                        } else if let error = authService.errorMessage {
                                            showToastMessage(error)
                                            authService.errorMessage = nil
                                        }
                                    }
                                }
                            } label: {
                                Text("Verify & Continue")
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.primaryPurple, Color.pinkAccent],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .opacity(otpCode.count == 6 ? 1 : 0.5)
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(otpCode.count != 6)
                            .padding(.horizontal, 24)

                            Button {
                                // Resend OTP
                                Task {
                                    let fullNumber = "+91\(phoneNumber)"
                                    if let id = await authService.sendVerificationCode(to: fullNumber) {
                                        verificationID = id
                                        showToastMessage("OTP sent successfully!")
                                    }
                                }
                            } label: {
                                Text("Didn't receive code? Resend")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }
                    }
                }

                // Toast notification
                if showToast, let message = toastMessage {
                    VStack {
                        Spacer()

                        Text(message)
                            .font(Theme.Typography.subheadlineMedium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(toastMessage?.contains("success") == true ? Color.greenAccent : Color.red.opacity(0.9))
                            .cornerRadius(25)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.3), value: showToast)
                }

                if authService.isLoading {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle(showingVerification ? "Verify OTP" : "Phone Sign-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
        }
    }

    private func handleOTPInput(index: Int, oldValue: String, newValue: String) {
        // Only allow digits
        let filtered = newValue.filter { $0.isNumber }

        if filtered.count > 1 {
            // Handle paste - distribute digits across boxes
            let digits = Array(filtered.prefix(6 - index))
            for (i, digit) in digits.enumerated() {
                if index + i < 6 {
                    otpDigits[index + i] = String(digit)
                }
            }
            // Dismiss keyboard if all digits filled
            if index + digits.count >= 6 {
                focusedField = nil
            } else {
                focusedField = min(index + digits.count, 5)
            }
        } else if filtered.count == 1 {
            otpDigits[index] = filtered
            // Move to next field or dismiss keyboard on last digit
            if index < 5 {
                focusedField = index + 1
            } else {
                // Last digit entered - dismiss keyboard
                focusedField = nil
            }
        } else if filtered.isEmpty && !oldValue.isEmpty {
            otpDigits[index] = ""
            // Move to previous field on delete
            if index > 0 {
                focusedField = index - 1
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
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

#Preview {
    SignInView()
        .environmentObject(AuthenticationService())
}
