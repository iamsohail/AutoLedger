import Foundation

/// Service to provide Indian vehicle makes and models from local database
final class VehicleDataService {
    static let shared = VehicleDataService()

    private var vehicleData: IndianVehicleData?

    private init() {
        loadVehicleData()
    }

    // MARK: - Load Local Data

    private func loadVehicleData() {
        guard let url = Bundle.main.url(forResource: "IndianVehicleData", withExtension: "json") else {
            print("IndianVehicleData.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            vehicleData = try decoder.decode(IndianVehicleData.self, from: data)
            print("Loaded \(vehicleData?.makes.count ?? 0) vehicle makes")
        } catch {
            print("Error loading vehicle data: \(error)")
        }
    }

    // MARK: - Get Makes

    func getMakes() -> [IndianVehicleMake] {
        return vehicleData?.makes ?? []
    }

    func getMakeNames() -> [String] {
        return vehicleData?.makes.map { $0.name } ?? []
    }

    // MARK: - Get Models for Make

    func getModels(forMake makeName: String) -> [String] {
        guard let make = vehicleData?.makes.first(where: { $0.name == makeName }) else {
            return []
        }
        return make.models
    }

    func getModels(forMakeId makeId: String) -> [String] {
        guard let make = vehicleData?.makes.first(where: { $0.id == makeId }) else {
            return []
        }
        return make.models
    }

    // MARK: - Search

    func searchMakes(query: String) -> [IndianVehicleMake] {
        guard !query.isEmpty else { return getMakes() }
        let lowercasedQuery = query.lowercased()
        return vehicleData?.makes.filter {
            $0.name.lowercased().contains(lowercasedQuery)
        } ?? []
    }

    func searchModels(forMake makeName: String, query: String) -> [String] {
        let models = getModels(forMake: makeName)
        guard !query.isEmpty else { return models }
        let lowercasedQuery = query.lowercased()
        return models.filter { $0.lowercased().contains(lowercasedQuery) }
    }
}

// MARK: - Data Models

struct IndianVehicleData: Codable {
    let makes: [IndianVehicleMake]
}

struct IndianVehicleMake: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let country: String
    let models: [String]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: IndianVehicleMake, rhs: IndianVehicleMake) -> Bool {
        lhs.id == rhs.id
    }
}
