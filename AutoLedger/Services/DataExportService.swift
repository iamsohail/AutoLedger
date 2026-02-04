import Foundation
import SwiftData

final class DataExportService {
    static let shared = DataExportService()

    private init() {}

    struct FuelExportRow: Codable {
        let date: String
        let vehicleName: String
        let odometer: Double
        let quantity: Double
        let pricePerUnit: Double
        let totalCost: Double
        let fuelGrade: String
        let station: String?
        let isFullTank: Bool
    }

    struct MaintenanceExportRow: Codable {
        let date: String
        let vehicleName: String
        let odometer: Double
        let serviceType: String
        let cost: Double
        let laborCost: Double
        let partsCost: Double
        let serviceProvider: String?
    }

    struct TripExportRow: Codable {
        let date: String
        let vehicleName: String
        let startOdometer: Double
        let endOdometer: Double?
        let distance: Double
        let tripType: String
        let purpose: String?
        let reimbursementAmount: Double?
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func exportFuelEntriesToCSV(entries: [FuelEntry], vehicleName: String) -> String {
        var csv = "Date,Vehicle,Odometer,Quantity,Price Per Unit,Total Cost,Fuel Grade,Station,Full Tank\n"

        for entry in entries.sorted(by: { $0.date > $1.date }) {
            let row = [
                dateFormatter.string(from: entry.date),
                vehicleName,
                String(format: "%.1f", entry.odometer),
                String(format: "%.3f", entry.quantity),
                String(format: "%.3f", entry.pricePerUnit),
                String(format: "%.2f", entry.totalCost),
                entry.fuelGrade.rawValue,
                entry.station ?? "",
                entry.isFullTank ? "Yes" : "No"
            ]
            csv += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }

        return csv
    }

    func exportMaintenanceToCSV(records: [MaintenanceRecord], vehicleName: String) -> String {
        var csv = "Date,Vehicle,Odometer,Service Type,Total Cost,Labor Cost,Parts Cost,Service Provider\n"

        for record in records.sorted(by: { $0.date > $1.date }) {
            let row = [
                dateFormatter.string(from: record.date),
                vehicleName,
                String(format: "%.1f", record.odometer),
                record.displayName,
                String(format: "%.2f", record.cost),
                String(format: "%.2f", record.laborCost),
                String(format: "%.2f", record.partsCost),
                record.serviceProvider ?? ""
            ]
            csv += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }

        return csv
    }

    func exportTripsToCSV(trips: [Trip], vehicleName: String) -> String {
        var csv = "Date,Vehicle,Start Odometer,End Odometer,Distance,Trip Type,Purpose,Reimbursement Amount\n"

        for trip in trips.sorted(by: { $0.date > $1.date }) {
            let row = [
                dateFormatter.string(from: trip.date),
                vehicleName,
                String(format: "%.1f", trip.startOdometer),
                trip.endOdometer != nil ? String(format: "%.1f", trip.endOdometer!) : "",
                String(format: "%.1f", trip.calculatedDistance),
                trip.tripType.rawValue,
                trip.purpose ?? "",
                trip.reimbursementAmount != nil ? String(format: "%.2f", trip.reimbursementAmount!) : ""
            ]
            csv += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }

        return csv
    }

    func exportAllDataToJSON(vehicles: [Vehicle]) throws -> Data {
        var exportData: [[String: Any]] = []

        for vehicle in vehicles {
            var vehicleData: [String: Any] = [
                "name": vehicle.name,
                "make": vehicle.make,
                "model": vehicle.model,
                "year": vehicle.year,
                "currentOdometer": vehicle.currentOdometer,
                "odometerUnit": vehicle.odometerUnit.rawValue,
                "fuelType": vehicle.fuelType.rawValue
            ]

            if let entries = vehicle.fuelEntries {
                vehicleData["fuelEntries"] = entries.map { entry in
                    [
                        "date": dateFormatter.string(from: entry.date),
                        "odometer": entry.odometer,
                        "quantity": entry.quantity,
                        "pricePerUnit": entry.pricePerUnit,
                        "totalCost": entry.totalCost,
                        "fuelGrade": entry.fuelGrade.rawValue,
                        "isFullTank": entry.isFullTank
                    ]
                }
            }

            if let records = vehicle.maintenanceRecords {
                vehicleData["maintenanceRecords"] = records.map { record in
                    [
                        "date": dateFormatter.string(from: record.date),
                        "odometer": record.odometer,
                        "serviceType": record.displayName,
                        "cost": record.cost,
                        "laborCost": record.laborCost,
                        "partsCost": record.partsCost
                    ]
                }
            }

            exportData.append(vehicleData)
        }

        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}
