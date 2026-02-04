import Foundation
import SwiftData

@Model
final class FuelEntry {
    var id: UUID
    var date: Date
    var odometer: Double
    var quantity: Double
    var pricePerUnit: Double
    var totalCost: Double
    var isFullTank: Bool
    var fuelGrade: FuelGrade
    var station: String?
    var location: String?
    var notes: String?
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        odometer: Double,
        quantity: Double,
        pricePerUnit: Double,
        isFullTank: Bool = true,
        fuelGrade: FuelGrade = .regular,
        station: String? = nil,
        location: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.odometer = odometer
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.totalCost = quantity * pricePerUnit
        self.isFullTank = isFullTank
        self.fuelGrade = fuelGrade
        self.station = station
        self.location = location
        self.notes = notes
        self.createdAt = Date()
    }

    var fuelEconomy: Double? {
        guard let vehicle = vehicle,
              let entries = vehicle.fuelEntries,
              isFullTank else { return nil }

        let sortedEntries = entries.sorted { $0.date < $1.date }
        guard let currentIndex = sortedEntries.firstIndex(where: { $0.id == self.id }),
              currentIndex > 0 else { return nil }

        let previousEntry = sortedEntries[currentIndex - 1]
        guard previousEntry.isFullTank else { return nil }

        let distance = odometer - previousEntry.odometer
        guard distance > 0 else { return nil }

        return distance / quantity
    }
}

enum FuelGrade: String, Codable, CaseIterable {
    case regular = "Regular"
    case midGrade = "Mid-Grade"
    case premium = "Premium"
    case diesel = "Diesel"
    case e85 = "E85"
}

enum VolumeUnit: String, Codable, CaseIterable {
    case gallons = "gallons"
    case liters = "liters"

    var abbreviation: String {
        switch self {
        case .gallons: return "gal"
        case .liters: return "L"
        }
    }
}
