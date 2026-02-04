import Foundation

enum AppConstants {
    enum UserDefaults {
        static let selectedVehicleId = "selectedVehicleId"
        static let preferredOdometerUnit = "preferredOdometerUnit"
        static let preferredVolumeUnit = "preferredVolumeUnit"
        static let preferredCurrency = "preferredCurrency"
        static let enableNotifications = "enableNotifications"
        static let maintenanceReminderDays = "maintenanceReminderDays"
        static let documentExpirationReminderDays = "documentExpirationReminderDays"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    enum Notifications {
        static let defaultMaintenanceReminderDays = 7
        static let defaultDocumentExpirationReminderDays = 30
    }

    enum IRS {
        // 2024 IRS standard mileage rates
        static let businessMileageRate: Double = 0.67
        static let medicalMileageRate: Double = 0.21
        static let charityMileageRate: Double = 0.14
    }

    enum Limits {
        static let maxVehicleNameLength = 50
        static let maxNotesLength = 500
        static let maxImageSizeBytes = 5 * 1024 * 1024 // 5MB
    }
}

enum AppError: LocalizedError {
    case dataNotFound
    case invalidInput(String)
    case exportFailed(String)
    case notificationFailed(String)
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "The requested data could not be found."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .notificationFailed(let message):
            return "Notification failed: \(message)"
        case .imageTooLarge:
            return "The image is too large. Please select a smaller image."
        }
    }
}
