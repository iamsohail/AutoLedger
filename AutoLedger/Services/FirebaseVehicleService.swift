import Foundation
import FirebaseFirestore

/// Service to fetch vehicle makes and models from Firebase Firestore
@MainActor
final class FirebaseVehicleService: ObservableObject {
    static let shared = FirebaseVehicleService()

    @Published var makes: [VehicleMakeData] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private let makesCollection = "vehicle_makes"

    private init() {}

    // MARK: - Fetch All Makes

    func fetchMakes() async {
        isLoading = true
        error = nil

        do {
            let snapshot = try await db.collection(makesCollection)
                .order(by: "name")
                .getDocuments()

            let fetchedMakes = snapshot.documents.compactMap { doc -> VehicleMakeData? in
                try? doc.data(as: VehicleMakeData.self)
            }

            self.makes = fetchedMakes
            isLoading = false

            // Cache locally for offline use
            cacheLocally(fetchedMakes)

        } catch {
            self.error = "Failed to fetch makes: \(error.localizedDescription)"
            isLoading = false

            // Load from cache if network fails
            loadFromCache()
        }
    }

    // MARK: - Fetch Models for Make

    func fetchModels(forMakeId makeId: String) async -> [String] {
        // First check if we already have it in memory
        if let make = makes.first(where: { $0.id == makeId }) {
            return make.models
        }

        // Otherwise fetch from Firestore
        do {
            let doc = try await db.collection(makesCollection).document(makeId).getDocument()
            if let make = try? doc.data(as: VehicleMakeData.self) {
                return make.models
            }
        } catch {
            print("Error fetching models: \(error)")
        }

        return []
    }

    // MARK: - Search

    func searchMakes(query: String) -> [VehicleMakeData] {
        guard !query.isEmpty else { return makes }
        let lowercased = query.lowercased()
        return makes.filter { $0.name.lowercased().contains(lowercased) }
    }

    // MARK: - Local Cache

    private func cacheLocally(_ makes: [VehicleMakeData]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(makes) {
            UserDefaults.standard.set(data, forKey: "cached_vehicle_makes")
            UserDefaults.standard.set(Date(), forKey: "cached_vehicle_makes_date")
        }
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: "cached_vehicle_makes") else {
            // Fall back to bundled data if no cache
            loadBundledData()
            return
        }

        let decoder = JSONDecoder()
        if let cached = try? decoder.decode([VehicleMakeData].self, from: data) {
            self.makes = cached
        } else {
            loadBundledData()
        }
    }

    private func loadBundledData() {
        guard let url = Bundle.main.url(forResource: "IndianVehicleData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let localData = try? JSONDecoder().decode(IndianVehicleData.self, from: data) else {
            return
        }

        // Convert bundled format to VehicleMakeData format
        self.makes = localData.makes.map { make in
            VehicleMakeData(
                id: make.id,
                name: make.name,
                country: make.country,
                models: make.models
            )
        }
    }

    // MARK: - Check if cache is stale (older than 24 hours)

    var isCacheStale: Bool {
        guard let cacheDate = UserDefaults.standard.object(forKey: "cached_vehicle_makes_date") as? Date else {
            return true
        }
        let hoursSinceCache = Date().timeIntervalSince(cacheDate) / 3600
        return hoursSinceCache > 24
    }
}

// MARK: - Data Models

struct VehicleMakeData: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
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
