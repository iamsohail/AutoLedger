import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String?
    var phone: String?
    var photoURL: String?
    var authProvider: AuthProvider
    var createdAt: Date
    var updatedAt: Date

    enum AuthProvider: String, Codable {
        case email
        case google
        case apple
        case phone
    }

    var isProfileComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(
        id: String? = nil,
        name: String = "",
        email: String? = nil,
        phone: String? = nil,
        photoURL: String? = nil,
        authProvider: AuthProvider,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.photoURL = photoURL
        self.authProvider = authProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
