import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var date: Date
    var startOdometer: Double
    var endOdometer: Double?
    var distance: Double?
    var tripType: TripType
    var purpose: String?
    var startLocation: String?
    var endLocation: String?
    var notes: String?
    var isActive: Bool
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        startOdometer: Double,
        tripType: TripType = .personal,
        purpose: String? = nil,
        startLocation: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startOdometer = startOdometer
        self.tripType = tripType
        self.purpose = purpose
        self.startLocation = startLocation
        self.isActive = true
        self.createdAt = Date()
    }

    var calculatedDistance: Double {
        if let distance = distance {
            return distance
        }
        if let endOdometer = endOdometer {
            return endOdometer - startOdometer
        }
        return 0
    }

    func endTrip(endOdometer: Double, endLocation: String? = nil) {
        self.endOdometer = endOdometer
        self.distance = endOdometer - startOdometer
        self.endLocation = endLocation
        self.isActive = false
    }

    // IRS standard mileage rate for 2024 (can be updated)
    static let businessMileageRate: Double = 0.67

    var reimbursementAmount: Double? {
        guard tripType == .business else { return nil }
        return calculatedDistance * Trip.businessMileageRate
    }
}

enum TripType: String, Codable, CaseIterable {
    case personal = "Personal"
    case business = "Business"
    case commute = "Commute"
    case medical = "Medical"
    case charity = "Charity"
    case moving = "Moving"

    var icon: String {
        switch self {
        case .personal: return "car.fill"
        case .business: return "briefcase.fill"
        case .commute: return "building.2.fill"
        case .medical: return "cross.case.fill"
        case .charity: return "heart.fill"
        case .moving: return "shippingbox.fill"
        }
    }

    var isTaxDeductible: Bool {
        switch self {
        case .business, .medical, .charity, .moving:
            return true
        case .personal, .commute:
            return false
        }
    }
}
