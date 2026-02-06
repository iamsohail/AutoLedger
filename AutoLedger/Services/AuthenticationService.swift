import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var userProfile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsProfileCompletion = false

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var pendingAppleName: PersonNameComponents?
    private var pendingAuthProvider: UserProfile.AuthProvider?
    private var pendingPhoneNumber: String?

    private let db = Firestore.firestore()

    init() {
        registerAuthStateHandler()
    }

    private func registerAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.user = user
            self.isAuthenticated = user != nil

            if let user = user {
                Task {
                    await self.fetchOrCreateUserProfile(for: user)
                    self.isCheckingAuth = false
                }
            } else {
                self.userProfile = nil
                self.needsProfileCompletion = false
                self.isCheckingAuth = false
            }
        }
    }

    // MARK: - User Profile Management

    private func fetchOrCreateUserProfile(for user: User) async {
        let docRef = db.collection("users").document(user.uid)

        do {
            let document = try await docRef.getDocument()

            if document.exists {
                // Fetch existing profile
                userProfile = try document.data(as: UserProfile.self)
                needsProfileCompletion = !(userProfile?.isProfileComplete ?? false)
            } else {
                // Create new profile
                let provider = pendingAuthProvider ?? determineAuthProvider(for: user)
                var newProfile = UserProfile(
                    id: user.uid,
                    name: pendingAppleName?.formatted() ?? user.displayName ?? "",
                    email: user.email,
                    phone: pendingPhoneNumber ?? user.phoneNumber,
                    photoURL: user.photoURL?.absoluteString,
                    authProvider: provider
                )

                // Save to Firestore
                try docRef.setData(from: newProfile)
                userProfile = newProfile
                needsProfileCompletion = !newProfile.isProfileComplete

                // Clear pending data
                pendingAppleName = nil
                pendingAuthProvider = nil
                pendingPhoneNumber = nil
            }
        } catch {
            print("Error fetching/creating user profile: \(error)")
            // Create a basic profile from auth data
            let provider = pendingAuthProvider ?? determineAuthProvider(for: user)
            userProfile = UserProfile(
                id: user.uid,
                name: user.displayName ?? "",
                email: user.email,
                phone: user.phoneNumber,
                photoURL: user.photoURL?.absoluteString,
                authProvider: provider
            )
            needsProfileCompletion = !(userProfile?.isProfileComplete ?? false)
        }
    }

    private func determineAuthProvider(for user: User) -> UserProfile.AuthProvider {
        for info in user.providerData {
            switch info.providerID {
            case "google.com":
                return .google
            case "apple.com":
                return .apple
            case "phone":
                return .phone
            default:
                continue
            }
        }
        return .email
    }

    func updateUserProfile(name: String, email: String?, phone: String?) async -> Bool {
        guard let userId = user?.uid else { return false }

        isLoading = true

        do {
            let docRef = db.collection("users").document(userId)
            try await docRef.updateData([
                "name": name,
                "email": email as Any,
                "phone": phone as Any,
                "updatedAt": Date()
            ])

            // Update local profile
            userProfile?.name = name
            userProfile?.email = email
            userProfile?.phone = phone
            userProfile?.updatedAt = Date()
            needsProfileCompletion = false

            isLoading = false
            return true
        } catch {
            print("Error updating profile: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Email/Password Auth

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        pendingAuthProvider = .email

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        pendingAuthProvider = .email

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Apple Sign In

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    errorMessage = "Unable to fetch identity token"
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    errorMessage = "Unable to serialize token string from data"
                    return
                }

                // Save Apple name immediately (only provided on first sign-in!)
                pendingAppleName = appleIDCredential.fullName
                pendingAuthProvider = .apple

                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )

                Task {
                    await signInWithCredential(credential)
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func signInWithCredential(_ credential: AuthCredential) async {
        isLoading = true
        errorMessage = nil

        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        pendingAuthProvider = .google

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google Client ID"
            isLoading = false
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            isLoading = false
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                isLoading = false
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Phone Auth

    func sendVerificationCode(to phoneNumber: String) async -> String? {
        isLoading = true
        errorMessage = nil
        pendingPhoneNumber = phoneNumber
        pendingAuthProvider = .phone

        // Enable app verification disabled for testing on simulator
        #if targetEnvironment(simulator)
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        #endif

        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(
                phoneNumber,
                uiDelegate: nil
            )
            isLoading = false
            return verificationID
        } catch {
            isLoading = false
            let nsError = error as NSError
            print("Firebase Phone Auth Error: \(nsError.domain) - \(nsError.code) - \(nsError.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func verifyCode(_ code: String, verificationID: String) async {
        isLoading = true
        errorMessage = nil

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        do {
            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            userProfile = nil
            needsProfileCompletion = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
