import Foundation

/// Service to fetch vehicle makes, models, and trims from CarQuery API
final class VehicleDataService {
    static let shared = VehicleDataService()

    private let baseURL = "https://www.carqueryapi.com/api/0.3/"
    private let session: URLSession

    // Cache for makes and models
    private var makesCache: [Int: [VehicleMake]] = [:]
    private var modelsCache: [String: [VehicleModel]] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
    }

    // MARK: - Get Years

    func getAvailableYears() -> [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1990...(currentYear + 1)).reversed())
    }

    // MARK: - Get Makes

    func getMakes(year: Int) async throws -> [VehicleMake] {
        // Check cache first
        if let cached = makesCache[year] {
            return cached
        }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "cmd", value: "getMakes"),
            URLQueryItem(name: "year", value: String(year))
        ]

        guard let url = components.url else {
            throw VehicleDataError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VehicleDataError.serverError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(MakesResponse.self, from: data)

        let makes = result.Makes.sorted { $0.makeDisplay < $1.makeDisplay }
        makesCache[year] = makes

        return makes
    }

    // MARK: - Get Models

    func getModels(make: String, year: Int) async throws -> [VehicleModel] {
        let cacheKey = "\(make)_\(year)"

        // Check cache first
        if let cached = modelsCache[cacheKey] {
            return cached
        }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "cmd", value: "getModels"),
            URLQueryItem(name: "make", value: make.lowercased()),
            URLQueryItem(name: "year", value: String(year))
        ]

        guard let url = components.url else {
            throw VehicleDataError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VehicleDataError.serverError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(ModelsResponse.self, from: data)

        let models = result.Models.sorted { $0.modelName < $1.modelName }
        modelsCache[cacheKey] = models

        return models
    }

    // MARK: - Get Trims (with specs)

    func getTrims(make: String, model: String, year: Int) async throws -> [VehicleTrim] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "cmd", value: "getTrims"),
            URLQueryItem(name: "make", value: make.lowercased()),
            URLQueryItem(name: "model", value: model),
            URLQueryItem(name: "year", value: String(year))
        ]

        guard let url = components.url else {
            throw VehicleDataError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VehicleDataError.serverError
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(TrimsResponse.self, from: data)

        return result.Trims
    }

    // MARK: - Clear Cache

    func clearCache() {
        makesCache.removeAll()
        modelsCache.removeAll()
    }
}

// MARK: - Response Models

struct MakesResponse: Codable {
    let Makes: [VehicleMake]
}

struct VehicleMake: Codable, Identifiable, Hashable {
    let makeId: String
    let makeDisplay: String
    let makeIsCommon: String?
    let makeCountry: String?

    var id: String { makeId }

    enum CodingKeys: String, CodingKey {
        case makeId = "make_id"
        case makeDisplay = "make_display"
        case makeIsCommon = "make_is_common"
        case makeCountry = "make_country"
    }
}

struct ModelsResponse: Codable {
    let Models: [VehicleModel]
}

struct VehicleModel: Codable, Identifiable, Hashable {
    let modelName: String
    let modelMakeId: String

    var id: String { "\(modelMakeId)_\(modelName)" }

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case modelMakeId = "model_make_id"
    }
}

struct TrimsResponse: Codable {
    let Trims: [VehicleTrim]
}

struct VehicleTrim: Codable, Identifiable {
    let modelId: String?
    let modelMakeId: String?
    let modelName: String?
    let modelTrim: String?
    let modelYear: String?
    let modelBody: String?
    let modelEnginePosition: String?
    let modelEngineCC: String?
    let modelEngineCyl: String?
    let modelEngineType: String?
    let modelEngineFuel: String?
    let modelDrive: String?
    let modelTransmissionType: String?
    let modelDoors: String?
    let modelSeats: String?
    let modelWeight: String?
    let modelLkm: String? // Fuel consumption L/100km
    let modelFuelCap: String? // Fuel tank capacity

    var id: String { modelId ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case modelMakeId = "model_make_id"
        case modelName = "model_name"
        case modelTrim = "model_trim"
        case modelYear = "model_year"
        case modelBody = "model_body"
        case modelEnginePosition = "model_engine_position"
        case modelEngineCC = "model_engine_cc"
        case modelEngineCyl = "model_engine_cyl"
        case modelEngineType = "model_engine_type"
        case modelEngineFuel = "model_engine_fuel"
        case modelDrive = "model_drive"
        case modelTransmissionType = "model_transmission_type"
        case modelDoors = "model_doors"
        case modelSeats = "model_seats"
        case modelWeight = "model_weight_kg"
        case modelLkm = "model_lkm_mixed"
        case modelFuelCap = "model_fuel_cap_l"
    }

    var displayName: String {
        if let trim = modelTrim, !trim.isEmpty {
            return trim
        }
        return "Base"
    }

    var fuelCapacityLiters: Double? {
        guard let cap = modelFuelCap else { return nil }
        return Double(cap)
    }

    var fuelCapacityGallons: Double? {
        guard let liters = fuelCapacityLiters else { return nil }
        return liters * 0.264172
    }
}

// MARK: - Errors

enum VehicleDataError: LocalizedError {
    case invalidURL
    case serverError
    case noData
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error. Please try again."
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
