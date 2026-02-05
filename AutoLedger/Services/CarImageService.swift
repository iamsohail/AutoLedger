import Foundation

enum CarImageAngle: Int {
    case front = 1
    case frontQuarter = 29
    case side = 13
    case rear = 5
    case rearQuarter = 17
}

enum CarImageService {
    private static let baseURL = "https://cdn.imagin.studio/getimage"
    private static let customer = "hrjavascript-mastery"

    /// Generates a URL for a car image from Imagin.studio
    /// - Parameters:
    ///   - make: Vehicle manufacturer (e.g., "Toyota", "Volkswagen")
    ///   - model: Vehicle model (e.g., "Camry", "Taigun")
    ///   - year: Model year (e.g., 2024)
    ///   - angle: Camera angle for the image
    ///   - color: Optional paint color description
    /// - Returns: URL for the car image
    static func imageURL(
        make: String,
        model: String,
        year: Int,
        angle: CarImageAngle = .frontQuarter,
        color: String? = nil
    ) -> URL? {
        var components = URLComponents(string: baseURL)

        var queryItems = [
            URLQueryItem(name: "customer", value: customer),
            URLQueryItem(name: "make", value: make),
            URLQueryItem(name: "modelFamily", value: model),
            URLQueryItem(name: "modelYear", value: String(year)),
            URLQueryItem(name: "angle", value: String(angle.rawValue)),
            URLQueryItem(name: "zoomType", value: "fullscreen")
        ]

        if let color = color {
            queryItems.append(URLQueryItem(name: "paintdescription", value: color))
        }

        components?.queryItems = queryItems
        return components?.url
    }

    /// Generates a URL for a car image from a Vehicle object
    static func imageURL(for vehicle: Vehicle, angle: CarImageAngle = .frontQuarter) -> URL? {
        return imageURL(
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year,
            angle: angle,
            color: vehicle.color?.lowercased().replacingOccurrences(of: " ", with: "-")
        )
    }
}
