import Foundation
import SwiftData

@Model
final class ParkingSpot {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var address: String?
    var floor: String?
    var spotNumber: String?
    var notes: String?
    var photoData: Data?
    var timestamp: Date
    var isActive: Bool

    var vehicle: Vehicle?

    init(
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        floor: String? = nil,
        spotNumber: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.floor = floor
        self.spotNumber = spotNumber
        self.notes = notes
        self.timestamp = Date()
        self.isActive = true
    }
}
