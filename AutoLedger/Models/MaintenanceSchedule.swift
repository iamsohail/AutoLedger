import Foundation
import SwiftData

@Model
final class MaintenanceSchedule {
    var id: UUID
    var serviceType: ServiceType
    var customServiceName: String?
    var mileageInterval: Double?
    var timeIntervalMonths: Int?
    var lastServiceDate: Date?
    var lastServiceOdometer: Double?
    var isEnabled: Bool
    var notes: String?
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        serviceType: ServiceType,
        customServiceName: String? = nil,
        mileageInterval: Double? = nil,
        timeIntervalMonths: Int? = nil
    ) {
        self.id = UUID()
        self.serviceType = serviceType
        self.customServiceName = customServiceName
        self.mileageInterval = mileageInterval ?? serviceType.defaultMileageInterval
        self.timeIntervalMonths = timeIntervalMonths ?? serviceType.defaultTimeInterval
        self.isEnabled = true
        self.createdAt = Date()
    }

    var displayName: String {
        if serviceType == .custom, let customName = customServiceName {
            return customName
        }
        return serviceType.displayName
    }

    func nextDueMileage(currentOdometer: Double) -> Double? {
        guard let interval = mileageInterval,
              let lastOdometer = lastServiceOdometer else {
            return nil
        }
        return lastOdometer + interval
    }

    func nextDueDate() -> Date? {
        guard let interval = timeIntervalMonths,
              let lastDate = lastServiceDate else {
            return nil
        }
        return Calendar.current.date(byAdding: .month, value: interval, to: lastDate)
    }

    func isDueByMileage(currentOdometer: Double) -> Bool {
        guard let nextMileage = nextDueMileage(currentOdometer: currentOdometer) else {
            return false
        }
        return currentOdometer >= nextMileage
    }

    func isDueByDate() -> Bool {
        guard let nextDate = nextDueDate() else {
            return false
        }
        return Date() >= nextDate
    }

    func isDue(currentOdometer: Double) -> Bool {
        return isDueByMileage(currentOdometer: currentOdometer) || isDueByDate()
    }

    func milesUntilDue(currentOdometer: Double) -> Double? {
        guard let nextMileage = nextDueMileage(currentOdometer: currentOdometer) else {
            return nil
        }
        return max(0, nextMileage - currentOdometer)
    }

    func daysUntilDue() -> Int? {
        guard let nextDate = nextDueDate() else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDate)
        return components.day
    }
}
