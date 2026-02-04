import Foundation
import SwiftData

@Model
final class MaintenanceRecord {
    var id: UUID
    var date: Date
    var odometer: Double
    var serviceType: ServiceType
    var customServiceName: String?
    var cost: Double
    var laborCost: Double
    var partsCost: Double
    var serviceProvider: String?
    var serviceProviderPhone: String?
    var serviceProviderAddress: String?
    var notes: String?
    var receiptImageData: Data?
    var isScheduled: Bool
    var reminderDate: Date?
    var reminderOdometer: Double?
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        odometer: Double,
        serviceType: ServiceType,
        customServiceName: String? = nil,
        cost: Double = 0,
        laborCost: Double = 0,
        partsCost: Double = 0,
        serviceProvider: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.odometer = odometer
        self.serviceType = serviceType
        self.customServiceName = customServiceName
        self.cost = cost
        self.laborCost = laborCost
        self.partsCost = partsCost
        self.serviceProvider = serviceProvider
        self.notes = notes
        self.isScheduled = false
        self.createdAt = Date()
    }

    var displayName: String {
        if serviceType == .custom, let customName = customServiceName {
            return customName
        }
        return serviceType.displayName
    }
}

enum ServiceType: String, Codable, CaseIterable {
    case oilChange = "oil_change"
    case tireRotation = "tire_rotation"
    case tireReplacement = "tire_replacement"
    case brakeInspection = "brake_inspection"
    case brakePadReplacement = "brake_pad_replacement"
    case airFilter = "air_filter"
    case cabinFilter = "cabin_filter"
    case sparkPlugs = "spark_plugs"
    case transmission = "transmission"
    case coolant = "coolant"
    case battery = "battery"
    case alignment = "alignment"
    case balancing = "balancing"
    case inspection = "inspection"
    case emissions = "emissions"
    case timing = "timing"
    case belts = "belts"
    case wiperBlades = "wiper_blades"
    case headlights = "headlights"
    case acService = "ac_service"
    case carWash = "car_wash"
    case detailing = "detailing"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .oilChange: return "Oil Change"
        case .tireRotation: return "Tire Rotation"
        case .tireReplacement: return "Tire Replacement"
        case .brakeInspection: return "Brake Inspection"
        case .brakePadReplacement: return "Brake Pad Replacement"
        case .airFilter: return "Air Filter"
        case .cabinFilter: return "Cabin Filter"
        case .sparkPlugs: return "Spark Plugs"
        case .transmission: return "Transmission Service"
        case .coolant: return "Coolant Flush"
        case .battery: return "Battery Replacement"
        case .alignment: return "Wheel Alignment"
        case .balancing: return "Wheel Balancing"
        case .inspection: return "Vehicle Inspection"
        case .emissions: return "Emissions Test"
        case .timing: return "Timing Belt"
        case .belts: return "Belt Replacement"
        case .wiperBlades: return "Wiper Blades"
        case .headlights: return "Headlight Replacement"
        case .acService: return "A/C Service"
        case .carWash: return "Car Wash"
        case .detailing: return "Detailing"
        case .custom: return "Custom Service"
        }
    }

    var icon: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .tireRotation, .tireReplacement: return "circle.circle"
        case .brakeInspection, .brakePadReplacement: return "circle.slash"
        case .airFilter, .cabinFilter: return "wind"
        case .sparkPlugs: return "bolt.fill"
        case .transmission: return "gearshape.2.fill"
        case .coolant: return "thermometer.snowflake"
        case .battery: return "battery.100"
        case .alignment, .balancing: return "arrow.left.arrow.right"
        case .inspection: return "checkmark.shield.fill"
        case .emissions: return "smoke.fill"
        case .timing, .belts: return "arrow.triangle.2.circlepath"
        case .wiperBlades: return "wiper.rear.and.fluid"
        case .headlights: return "headlight.high.beam.fill"
        case .acService: return "snowflake"
        case .carWash, .detailing: return "car.side.fill"
        case .custom: return "wrench.and.screwdriver.fill"
        }
    }

    // Default intervals in miles
    var defaultMileageInterval: Double? {
        switch self {
        case .oilChange: return 5000
        case .tireRotation: return 7500
        case .airFilter: return 15000
        case .cabinFilter: return 15000
        case .sparkPlugs: return 30000
        case .transmission: return 60000
        case .coolant: return 30000
        case .timing: return 60000
        case .belts: return 60000
        default: return nil
        }
    }

    // Default intervals in months
    var defaultTimeInterval: Int? {
        switch self {
        case .oilChange: return 6
        case .tireRotation: return 6
        case .airFilter: return 12
        case .cabinFilter: return 12
        case .inspection: return 12
        case .emissions: return 24
        case .wiperBlades: return 12
        default: return nil
        }
    }
}
