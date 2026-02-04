import Foundation

/// Service to fetch vehicle makes and models
/// Currently uses local bundled data. Firebase integration can be re-enabled later.
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

        // Load from bundled data
        loadBundledData()

        isLoading = false
    }

    // MARK: - Fetch Models for Make

    func fetchModels(forMakeId makeId: String) async -> [String] {
        if let make = makes.first(where: { $0.id == makeId }) {
            return make.models
        }
        return []
    }

    // MARK: - Search

    func searchMakes(query: String) -> [VehicleMakeData] {
        guard !query.isEmpty else { return makes }
        let lowercased = query.lowercased()
        return makes.filter { $0.name.lowercased().contains(lowercased) }
    }

    // MARK: - Local Data

    private func loadBundledData() {
        guard let url = Bundle.main.url(forResource: "IndianVehicleData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            error = "Failed to load vehicle data"
            return
        }

        do {
            let localData = try JSONDecoder().decode(LocalVehicleData.self, from: data)

            // Convert bundled format to VehicleMakeData format
            self.makes = localData.makes.map { make in
                VehicleMakeData(
                    id: make.id,
                    name: make.name,
                    country: make.country,
                    models: make.models
                )
            }
        } catch {
            self.error = "Failed to parse vehicle data: \(error.localizedDescription)"
        }
    }

    // MARK: - Check if cache is stale

    var isCacheStale: Bool {
        return makes.isEmpty
    }
}

// MARK: - Data Models

struct VehicleMakeData: Codable, Identifiable, Hashable {
    var id: String?
    let name: String
    let country: String
    let models: [String]

    var documentId: String {
        id ?? UUID().uuidString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VehicleMakeData, rhs: VehicleMakeData) -> Bool {
        lhs.id == rhs.id
    }
}

// Local JSON structure
private struct LocalVehicleData: Codable {
    let makes: [LocalVehicleMake]
}

private struct LocalVehicleMake: Codable {
    let id: String
    let name: String
    let country: String
    let models: [String]
}
