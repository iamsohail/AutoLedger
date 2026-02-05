import Foundation
import SwiftData

/// Service to provide tank/battery capacity data for vehicles
struct TankCapacityService {

    struct CapacityData: Decodable {
        let tankL: Double?
        let batteryKWh: Double?

        var tankCapacityLitres: Double? { tankL }
        var batteryCapacityKWh: Double? { batteryKWh }
    }

    struct TankCapacityFile: Decodable {
        let version: String
        let lastUpdated: String
        let note: String
        let data: [String: CapacityData]
        let defaults: [String: Double]
    }

    private static var cachedData: [String: CapacityData]?
    private static var defaultValues: [String: Double]?

    /// Load tank capacity data from JSON file
    private static func loadData() {
        guard cachedData == nil else { return }

        guard let url = Bundle.main.url(forResource: "TankCapacityData", withExtension: "json") else {
            print("TankCapacityData.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(TankCapacityFile.self, from: data)
            cachedData = decoded.data
            defaultValues = decoded.defaults
        } catch {
            print("Failed to decode TankCapacityData.json: \(error)")
        }
    }

    /// Get tank capacity for a specific make and model
    /// - Parameters:
    ///   - make: Vehicle manufacturer (e.g., "Maruti Suzuki")
    ///   - model: Vehicle model (e.g., "Swift")
    /// - Returns: Tank capacity in litres, or nil if not found
    static func getTankCapacity(make: String, model: String) -> Double? {
        loadData()
        let key = "\(make)|\(model)"
        return cachedData?[key]?.tankL
    }

    /// Get battery capacity for EVs
    /// - Parameters:
    ///   - make: Vehicle manufacturer
    ///   - model: Vehicle model
    /// - Returns: Battery capacity in kWh, or nil if not found
    static func getBatteryCapacity(make: String, model: String) -> Double? {
        loadData()
        let key = "\(make)|\(model)"
        return cachedData?[key]?.batteryKWh
    }

    /// Get capacity (tank or battery) based on fuel type
    /// - Parameters:
    ///   - make: Vehicle manufacturer
    ///   - model: Vehicle model
    ///   - fuelType: Type of fuel the vehicle uses
    /// - Returns: Capacity in litres (for fuel) or kWh (for electric)
    static func getCapacity(make: String, model: String, fuelType: FuelType) -> Double? {
        loadData()
        let key = "\(make)|\(model)"

        if let data = cachedData?[key] {
            if fuelType == .electric {
                return data.batteryKWh
            } else {
                return data.tankL ?? data.batteryKWh // Some hybrids might have battery data
            }
        }

        return nil
    }

    /// Get default tank capacity based on fuel type and vehicle category
    /// - Parameters:
    ///   - fuelType: Type of fuel
    ///   - category: Vehicle category (hatchback, sedan, suv)
    /// - Returns: Default tank capacity in litres
    static func getDefaultCapacity(fuelType: FuelType, category: VehicleCategory = .sedan) -> Double {
        loadData()

        let key: String
        switch fuelType {
        case .electric:
            switch category {
            case .hatchback: key = "electric_small"
            case .sedan: key = "electric_medium"
            case .suv, .mpv, .pickup: key = "electric_large"
            }
        case .diesel:
            switch category {
            case .hatchback: key = "diesel_hatchback"
            case .sedan: key = "diesel_sedan"
            case .suv, .mpv, .pickup: key = "diesel_suv"
            }
        default: // petrol, hybrid, etc.
            switch category {
            case .hatchback: key = "petrol_hatchback"
            case .sedan: key = "petrol_sedan"
            case .suv, .mpv, .pickup: key = "petrol_suv"
            }
        }

        return defaultValues?[key] ?? 45.0
    }

    /// Check if capacity data exists for a make/model
    static func hasCapacityData(make: String, model: String) -> Bool {
        loadData()
        let key = "\(make)|\(model)"
        return cachedData?[key] != nil
    }

    /// Get unit label for capacity
    static func capacityUnit(for fuelType: FuelType) -> String {
        fuelType == .electric ? "kWh" : "L"
    }
}

/// Vehicle category for default capacity estimation
enum VehicleCategory: String, CaseIterable {
    case hatchback = "Hatchback"
    case sedan = "Sedan"
    case suv = "SUV"
    case mpv = "MPV"
    case pickup = "Pickup"
}
