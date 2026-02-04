import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    func scheduleMaintenanceReminder(
        id: String,
        title: String,
        body: String,
        date: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "maintenance_\(id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule maintenance reminder: \(error)")
            }
        }
    }

    func scheduleDocumentExpirationReminder(
        id: String,
        documentName: String,
        expirationDate: Date,
        daysBefore: Int = 30
    ) {
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBefore,
            to: expirationDate
        ) else { return }

        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Document Expiring Soon"
        content.body = "\(documentName) will expire in \(daysBefore) days"
        content.sound = .default
        content.categoryIdentifier = "DOCUMENT_EXPIRATION"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "document_\(id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule document expiration reminder: \(error)")
            }
        }
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
