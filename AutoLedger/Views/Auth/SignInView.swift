import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var showingPhoneAuth = false
    @State private var showingVerification = false

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo section
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.primaryPurple, Color.pinkAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.primaryPurple.opacity(0.4), radius: 20, x: 0, y: 10)

                            Image(systemName: "car.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 60)

                        Text("Auto Ledger")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.bottom, 40)

                    // Title
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .padding(.bottom, 32)

                    // Form fields
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            HStack {
                                TextField("name@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .foregroundColor(.textPrimary)

                                if !email.isEmpty {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.primaryPurple.opacity(0.6))
                                }
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            HStack {
                                SecureField("••••••••", text: $password)
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .foregroundColor(.textPrimary)

                                Image(systemName: "eye.slash.fill")
                                    .foregroundColor(.textSecondary.opacity(0.5))
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Confirm password for sign up
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)

                                HStack {
                                    SecureField("••••••••", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .foregroundColor(.textPrimary)

                                    if !confirmPassword.isEmpty {
                                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(password == confirmPassword ? .greenAccent : .red)
                                    }
                                }
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primaryPurple.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }

                        // Forgot password
                        if !isSignUp {
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    // Handle forgot password
                                }
                                .font(.subheadline)
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
                                await authService.signUp(email: email, password: password)
                            } else {
                                await authService.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.primaryPurple, Color.pinkAccent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.6)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Error message
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    // Or divider
                    HStack {
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .fill(Color.textSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)

                    // Social sign-in buttons
                    VStack(spacing: 12) {
                        // Sign in with Google (using Phone as proxy since Google requires web setup)
                        Button {
                            showingPhoneAuth = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                Text("Sign \(isSignUp ? "Up" : "In") with Phone")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Sign in with Apple
                        SignInWithAppleButton(isSignUp ? .signUp : .signIn) { request in
                            authService.handleSignInWithAppleRequest(request)
                        } onCompletion: { result in
                            authService.handleSignInWithAppleCompletion(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)

                    // Toggle sign in/up
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.textSecondary)
                        Button(isSignUp ? "Sign In" : "Sign Up") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp.toggle()
                                // Clear fields when toggling
                                password = ""
                                confirmPassword = ""
                            }
                        }
                        .foregroundColor(.primaryPurple)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }

            // Loading overlay
            if authService.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Please wait...")
                        .font(.subheadline)
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
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

struct PhoneAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService: AuthenticationService
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var showingVerification = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    if !showingVerification {
                        // Phone input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)

                            HStack(spacing: 12) {
                                Text("+91")
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)

                                TextField("9876543210", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                                    .foregroundColor(.textPrimary)
                                    .padding()
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                            }
                        }

                        Button {
                            Task {
                                let fullNumber = "+91\(phoneNumber)"
                                if let id = await authService.sendVerificationCode(to: fullNumber) {
                                    verificationID = id
                                    showingVerification = true
                                }
                            }
                        } label: {
                            Text("Send OTP")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.primaryPurple, Color.pinkAccent.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .disabled(phoneNumber.count < 10)
                        .opacity(phoneNumber.count < 10 ? 0.6 : 1)

                    } else {
                        // Verification code input
                        VStack(spacing: 16) {
                            Text("Enter the 6-digit code sent to")
                                .foregroundColor(.textSecondary)
                            Text("+91 \(phoneNumber)")
                                .foregroundColor(.textPrimary)
                                .fontWeight(.semibold)

                            TextField("000000", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .frame(width: 200)

                            Button {
                                Task {
                                    if let id = verificationID {
                                        await authService.verifyCode(verificationCode, verificationID: id)
                                        if authService.isAuthenticated {
                                            dismiss()
                                        }
                                    }
                                }
                            } label: {
                                Text("Verify")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.primaryPurple, Color.pinkAccent.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(verificationCode.count != 6)
                            .opacity(verificationCode.count != 6 ? 0.6 : 1)

                            Button("Change phone number") {
                                showingVerification = false
                                verificationCode = ""
                            }
                            .font(.subheadline)
                            .foregroundColor(.primaryPurple)
                        }
                    }

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .padding(24)

                if authService.isLoading {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Phone Sign In")
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
}

#Preview {
    SignInView()
        .environmentObject(AuthenticationService())
}
