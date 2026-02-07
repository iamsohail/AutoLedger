import SwiftUI

struct ProfileCompletionView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showSuccess = false

    private var authProvider: UserProfile.AuthProvider {
        authService.userProfile?.authProvider ?? .email
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // Header
                    VStack(spacing: 16) {
                        GradientAvatarView(
                            uid: authService.user?.uid,
                            name: authService.userProfile?.name,
                            photoURL: authService.userProfile?.photoURL,
                            size: 100
                        )

                        Text("Complete Your Profile")
                            .font(Theme.Typography.title2)
                            .foregroundColor(.textPrimary)

                        Text("Just a Few More Details to Get Started")
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 32)

                    // Form fields
                    VStack(spacing: 20) {
                        // Name field (always shown if empty)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(Theme.Typography.subheadlineMedium)
                                .foregroundColor(.textSecondary)

                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 20)

                                TextField("", text: $name, prompt: Text("Enter your name").foregroundColor(.textSecondary.opacity(0.5)))
                                    .keyboardType(.asciiCapable)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
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

                        // Email field (shown for phone auth)
                        if authProvider == .phone {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Email")
                                        .font(Theme.Typography.subheadlineMedium)
                                        .foregroundColor(.textSecondary)

                                    Text("(Optional)")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(.textSecondary.opacity(0.6))
                                }

                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 20)

                                    TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(.textSecondary.opacity(0.5)))
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
                            }
                        }

                        // Phone field (shown for email/Google/Apple auth)
                        if authProvider == .email || authProvider == .google || authProvider == .apple {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Phone Number")
                                        .font(Theme.Typography.subheadlineMedium)
                                        .foregroundColor(.textSecondary)

                                    Text("(Optional)")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(.textSecondary.opacity(0.6))
                                }

                                HStack(spacing: 12) {
                                    Text("+91")
                                        .foregroundColor(.textSecondary)

                                    TextField("", text: $phone, prompt: Text("Phone number").foregroundColor(.textSecondary.opacity(0.5)))
                                        .keyboardType(.phonePad)
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
                        }

                        // Pre-filled info display
                        if let profile = authService.userProfile {
                            VStack(alignment: .leading, spacing: 12) {
                                if let existingEmail = profile.email, !existingEmail.isEmpty, authProvider != .phone {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.greenAccent)
                                            .frame(width: 20)

                                        Text(existingEmail)
                                            .foregroundColor(.textPrimary)

                                        Spacer()

                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.greenAccent)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.greenAccent.opacity(0.1))
                                    .cornerRadius(12)
                                }

                                if let existingPhone = profile.phone, !existingPhone.isEmpty, authProvider == .phone {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .foregroundColor(.greenAccent)
                                            .frame(width: 20)

                                        Text(Self.formatPhoneDisplay(existingPhone))
                                            .foregroundColor(.textPrimary)

                                        Spacer()

                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.greenAccent)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.greenAccent.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Continue button
                    Button {
                        Task {
                            let phoneToSave = phone.isEmpty ? authService.userProfile?.phone : (phone.hasPrefix("+91") ? phone : "+91\(phone)")
                            let emailToSave = email.isEmpty ? authService.userProfile?.email : email.lowercased()

                            // Capitalize first letter of each word in name
                            let formattedName = name.split(separator: " ")
                                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                                .joined(separator: " ")

                            let success = await authService.updateUserProfile(
                                name: formattedName,
                                email: emailToSave,
                                phone: phoneToSave
                            )

                            if success {
                                showSuccess = true
                            }
                        }
                    } label: {
                        Text("Continue")
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
                                .opacity(isFormValid ? 1 : 0.5)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Skip button
                    if authService.userProfile?.name.isEmpty == false {
                        Button {
                            authService.needsProfileCompletion = false
                        } label: {
                            Text("Skip for Now")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 16)
                    }

                    Spacer().frame(height: 40)
                }
            }

            // Loading overlay
            if authService.isLoading {
                CarLoadingOverlay()
            }
        }
        .onAppear {
            // Pre-fill existing data
            if let profile = authService.userProfile {
                name = profile.name
                email = profile.email ?? ""
                phone = profile.phone?.replacingOccurrences(of: "+91", with: "") ?? ""
            }
        }
    }

    private static func formatPhoneDisplay(_ phone: String) -> String {
        // Format +919035794120 → +91 90357 94120
        var digits = phone
        var prefix = ""
        if digits.hasPrefix("+91") {
            prefix = "+91 "
            digits = String(digits.dropFirst(3))
        } else if digits.hasPrefix("+") {
            return phone // Non-Indian number, return as-is
        }
        guard digits.count == 10 else { return prefix + digits }
        return "\(prefix)\(digits.prefix(5)) \(digits.suffix(5))"
    }
}

#Preview {
    ProfileCompletionView()
        .environmentObject(AuthenticationService())
}
