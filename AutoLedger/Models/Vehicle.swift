import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var name: String
    var make: String
    var model: String
    var year: Int
    var vin: String?
    var licensePlate: String?
    var color: String?
    var purchaseDate: Date?
    var purchasePrice: Double?
    var currentOdometer: Double
    var odometerUnit: OdometerUnit
    var fuelType: FuelType
    var tankCapacity: Double?
    var imageData: Data?
    var notes: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // Insurance details
    var insuranceProvider: String?
    var insurancePolicyNumber: String?
    var insuranceExpirationDate: Date?

    // Registration details
    var registrationState: String?
    var registrationExpirationDate: Date?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \FuelEntry.vehicle)
    var fuelEntries: [FuelEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRecord.vehicle)
    var maintenanceRecords: [MaintenanceRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \Trip.vehicle)
    var trips: [Trip]? = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.vehicle)
    var expenses: [Expense]? = []

    @Relationship(deleteRule: .cascade, inverse: \Document.vehicle)
    var documents: [Document]? = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceSchedule.vehicle)
    var maintenanceSchedules: [MaintenanceSchedule]? = []

    init(
        name: String,
        make: String,
        model: String,
        year: Int,
        currentOdometer: Double = 0,
        odometerUnit: OdometerUnit = .miles,
        fuelType: FuelType = .gasoline
    ) {
        self.id = UUID()
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.currentOdometer = currentOdometer
        self.odometerUnit = odometerUnit
        self.fuelType = fuelType
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var displayName: String {
        if !name.isEmpty {
            return name
        }
        return "\(year) \(make) \(model)"
    }

    var totalFuelCost: Double {
        fuelEntries?.reduce(0) { $0 + $1.totalCost } ?? 0
    }

    var totalMaintenanceCost: Double {
        maintenanceRecords?.reduce(0) { $0 + $1.cost } ?? 0
    }

    var averageFuelEconomy: Double? {
        guard let entries = fuelEntries, entries.count > 1 else { return nil }
        let sortedEntries = entries.sorted { $0.date < $1.date }
        var totalDistance: Double = 0
        var totalFuel: Double = 0

        for i in 1..<sortedEntries.count {
            if sortedEntries[i].isFullTank && sortedEntries[i-1].isFullTank {
                totalDistance += sortedEntries[i].odometer - sortedEntries[i-1].odometer
                totalFuel += sortedEntries[i].quantity
            }
        }

        guard totalFuel > 0 else { return nil }
        return totalDistance / totalFuel
    }
}

enum OdometerUnit: String, Codable, CaseIterable {
    case miles = "miles"
    case kilometers = "km"

    var abbreviation: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }
}

enum FuelType: String, Codable, CaseIterable {
    case gasoline = "Gasoline"
    case diesel = "Diesel"
    case electric = "Electric"
    case hybrid = "Hybrid"
    case plugInHybrid = "Plug-in Hybrid"
    case hydrogen = "Hydrogen"
    case flexFuel = "Flex Fuel"
}
