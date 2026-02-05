import Foundation

/// Service to fetch vehicle makes and models from bundled JSON data
@MainActor
final class FirebaseVehicleService: ObservableObject {
    static let shared = FirebaseVehicleService()

    @Published var makes: [VehicleMakeData] = []
    @Published var isLoading = false
    @Published var error: String?

    private init() {}

    // MARK: - Fetch All Makes

    func fetchMakes() async {
        isLoading = true
        error = nil
        loadBundledData()
        isLoading = false
    }

    // MARK: - Get Models for Make

    func getModels(forMake makeName: String) -> [VehicleModelData] {
        guard let make = makes.first(where: { $0.name == makeName }) else {
            return []
        }
        return make.models
    }

    // MARK: - Get Model Details

    func getModelDetails(make makeName: String, model modelName: String) -> VehicleModelData? {
        guard let make = makes.first(where: { $0.name == makeName }) else {
            return nil
        }
        return make.models.first(where: { $0.name == modelName })
    }

    // MARK: - Search

    func searchMakes(query: String) -> [VehicleMakeData] {
        guard !query.isEmpty else { return makes }
        let lowercased = query.lowercased()
        return makes.filter { $0.name.lowercased().contains(lowercased) }
    }

    // MARK: - Local Data Loading

    private func loadBundledData() {
        guard let url = Bundle.main.url(forResource: "IndianVehicleData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            error = "Failed to load vehicle data"
            return
        }

        do {
            let vehicleData = try JSONDecoder().decode(VehicleDatabase.self, from: data)
            self.makes = vehicleData.makes
        } catch {
            self.error = "Failed to parse vehicle data: \(error.localizedDescription)"
            print("JSON Parse Error: \(error)")
        }
    }

    var isCacheStale: Bool {
        return makes.isEmpty
    }
}

// MARK: - Data Models

/// Root structure for the vehicle database JSON
struct VehicleDatabase: Codable {
    let version: String
    let lastUpdated: String
    let makes: [VehicleMakeData]
}

/// Vehicle make (manufacturer) with all its models
struct VehicleMakeData: Codable, Identifiable, Hashable {
    let name: String
    let models: [VehicleModelData]

    var id: String { name }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: VehicleMakeData, rhs: VehicleMakeData) -> Bool {
        lhs.name == rhs.name
    }
}

/// Vehicle model with specifications
struct VehicleModelData: Codable, Identifiable, Hashable {
    let name: String
    let fuelTypes: [String]
    let transmission: String
    let tankL: Double?
    let batteryKWh: Double?
    let discontinued: Bool?

    var id: String { name }

    /// Available fuel types as FuelType enums
    var availableFuelTypes: [FuelType] {
        fuelTypes.map { FuelType.from($0) }
    }

    /// Check if model supports both Manual and Automatic
    var hasBothTransmissions: Bool {
        transmission == "Both"
    }

    /// Available transmission options
    var transmissionOptions: [String] {
        switch transmission {
        case "Both": return ["Manual", "Automatic"]
        case "Manual": return ["Manual"]
        case "Automatic": return ["Automatic"]
        default: return ["Manual"]
        }
    }

    /// Tank capacity (for petrol/diesel/cng)
    var tankCapacity: Double? {
        tankL
    }

    /// Battery capacity (for electric vehicles)
    var batteryCapacity: Double? {
        batteryKWh
    }

    /// Is this model discontinued?
    var isDiscontinued: Bool {
        discontinued ?? false
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: VehicleModelData, rhs: VehicleModelData) -> Bool {
        lhs.name == rhs.name
    }
}
