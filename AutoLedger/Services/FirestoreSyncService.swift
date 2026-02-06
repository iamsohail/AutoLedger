import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftData

@MainActor
class FirestoreSyncService: ObservableObject {
    static let shared = FirestoreSyncService()

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var syncProgress: String?

    private let db = Firestore.firestore()

    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    private func userVehiclesRef() -> CollectionReference? {
        guard let uid = uid else { return nil }
        return db.collection("users").document(uid).collection("vehicles")
    }

    init() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }

    // MARK: - Public API

    /// Full sync: push local data to cloud, then pull missing records from cloud
    func sync(context: ModelContext) async {
        guard uid != nil else {
            syncError = "Please sign in to sync"
            return
        }

        isSyncing = true
        syncError = nil

        do {
            try await pushAll(context: context)
            try await pullMissing(context: context)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            syncProgress = nil
        } catch {
            syncError = error.localizedDescription
            syncProgress = nil
        }

        isSyncing = false
    }

    /// Backup only: push all local data to cloud
    func backupToCloud(context: ModelContext) async {
        guard uid != nil else {
            syncError = "Please sign in to back up"
            return
        }

        isSyncing = true
        syncError = nil

        do {
            try await pushAll(context: context)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            syncProgress = nil
        } catch {
            syncError = error.localizedDescription
            syncProgress = nil
        }

        isSyncing = false
    }

    /// Restore only: pull all cloud data into local, merging with existing
    func restoreFromCloud(context: ModelContext) async {
        guard uid != nil else {
            syncError = "Please sign in to restore"
            return
        }

        isSyncing = true
        syncError = nil

        do {
            try await pullMissing(context: context)

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
            syncProgress = nil
        } catch {
            syncError = error.localizedDescription
            syncProgress = nil
        }

        isSyncing = false
    }

    /// Delete all cloud data for the current user
    func deleteCloudData() async {
        guard let uid = uid else {
            syncError = "Not signed in"
            return
        }

        isSyncing = true
        syncError = nil
        syncProgress = "Deleting cloud data..."

        do {
            let vehiclesRef = db.collection("users").document(uid).collection("vehicles")
            let vehicles = try await vehiclesRef.getDocuments()

            let subcollections = ["fuelEntries", "maintenanceRecords", "maintenanceSchedules", "trips", "expenses", "documents"]

            for doc in vehicles.documents {
                for sub in subcollections {
                    let subDocs = try await doc.reference.collection(sub).getDocuments()
                    for subDoc in subDocs.documents {
                        try await subDoc.reference.delete()
                    }
                }
                try await doc.reference.delete()
            }

            lastSyncDate = nil
            UserDefaults.standard.removeObject(forKey: "lastSyncDate")
            syncProgress = nil
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }

    // MARK: - Push All Local Data to Cloud

    private func pushAll(context: ModelContext) async throws {
        guard let vehiclesRef = userVehiclesRef() else { return }

        let vehicles = try context.fetch(FetchDescriptor<Vehicle>())

        for (index, vehicle) in vehicles.enumerated() {
            syncProgress = "Backing up \(vehicle.displayName) (\(index + 1)/\(vehicles.count))..."

            let vehicleRef = vehiclesRef.document(vehicle.id.uuidString)
            try await vehicleRef.setData(encodeVehicle(vehicle))

            // Push fuel entries
            for entry in vehicle.fuelEntries ?? [] {
                try await vehicleRef.collection("fuelEntries")
                    .document(entry.id.uuidString)
                    .setData(encodeFuelEntry(entry))
            }

            // Push maintenance records
            for record in vehicle.maintenanceRecords ?? [] {
                try await vehicleRef.collection("maintenanceRecords")
                    .document(record.id.uuidString)
                    .setData(encodeMaintenanceRecord(record))
            }

            // Push maintenance schedules
            for schedule in vehicle.maintenanceSchedules ?? [] {
                try await vehicleRef.collection("maintenanceSchedules")
                    .document(schedule.id.uuidString)
                    .setData(encodeMaintenanceSchedule(schedule))
            }

            // Push trips
            for trip in vehicle.trips ?? [] {
                try await vehicleRef.collection("trips")
                    .document(trip.id.uuidString)
                    .setData(encodeTrip(trip))
            }

            // Push expenses
            for expense in vehicle.expenses ?? [] {
                try await vehicleRef.collection("expenses")
                    .document(expense.id.uuidString)
                    .setData(encodeExpense(expense))
            }

            // Push documents
            for doc in vehicle.documents ?? [] {
                try await vehicleRef.collection("documents")
                    .document(doc.id.uuidString)
                    .setData(encodeDocument(doc))
            }
        }
    }

    // MARK: - Pull Missing Records from Cloud

    private func pullMissing(context: ModelContext) async throws {
        guard let vehiclesRef = userVehiclesRef() else { return }

        let localVehicles = try context.fetch(FetchDescriptor<Vehicle>())
        let localVehicleMap = Dictionary(uniqueKeysWithValues: localVehicles.map { ($0.id, $0) })

        let cloudVehicles = try await vehiclesRef.getDocuments()

        for doc in cloudVehicles.documents {
            guard let vehicleId = UUID(uuidString: doc.documentID) else { continue }

            let data = doc.data()
            let vehicleName = data["name"] as? String ?? "Vehicle"
            syncProgress = "Restoring \(vehicleName)..."

            let vehicle: Vehicle

            if let existing = localVehicleMap[vehicleId] {
                // Update if cloud is newer
                if let cloudUpdated = (data["updatedAt"] as? Timestamp)?.dateValue(),
                   cloudUpdated > existing.updatedAt {
                    updateVehicle(existing, from: data)
                }
                vehicle = existing
            } else {
                vehicle = decodeVehicle(from: data, id: vehicleId)
                context.insert(vehicle)
            }

            let vehicleRef = vehiclesRef.document(doc.documentID)

            try await pullFuelEntries(for: vehicle, vehicleRef: vehicleRef, context: context)
            try await pullMaintenanceRecords(for: vehicle, vehicleRef: vehicleRef, context: context)
            try await pullMaintenanceSchedules(for: vehicle, vehicleRef: vehicleRef, context: context)
            try await pullTrips(for: vehicle, vehicleRef: vehicleRef, context: context)
            try await pullExpenses(for: vehicle, vehicleRef: vehicleRef, context: context)
            try await pullDocuments(for: vehicle, vehicleRef: vehicleRef, context: context)
        }

        try context.save()
    }

    // MARK: - Pull Subcollections

    private func pullFuelEntries(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.fuelEntries ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("fuelEntries").getDocuments()

        for doc in cloudDocs.documents {
            guard let entryId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(entryId) { continue }

            let entry = decodeFuelEntry(from: doc.data(), id: entryId)
            entry.vehicle = vehicle
            context.insert(entry)
        }
    }

    private func pullMaintenanceRecords(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.maintenanceRecords ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("maintenanceRecords").getDocuments()

        for doc in cloudDocs.documents {
            guard let recordId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(recordId) { continue }

            let record = decodeMaintenanceRecord(from: doc.data(), id: recordId)
            record.vehicle = vehicle
            context.insert(record)
        }
    }

    private func pullMaintenanceSchedules(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.maintenanceSchedules ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("maintenanceSchedules").getDocuments()

        for doc in cloudDocs.documents {
            guard let scheduleId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(scheduleId) { continue }

            let schedule = decodeMaintenanceSchedule(from: doc.data(), id: scheduleId)
            schedule.vehicle = vehicle
            context.insert(schedule)
        }
    }

    private func pullTrips(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.trips ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("trips").getDocuments()

        for doc in cloudDocs.documents {
            guard let tripId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(tripId) { continue }

            let trip = decodeTrip(from: doc.data(), id: tripId)
            trip.vehicle = vehicle
            context.insert(trip)
        }
    }

    private func pullExpenses(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.expenses ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("expenses").getDocuments()

        for doc in cloudDocs.documents {
            guard let expenseId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(expenseId) { continue }

            let expense = decodeExpense(from: doc.data(), id: expenseId)
            expense.vehicle = vehicle
            context.insert(expense)
        }
    }

    private func pullDocuments(for vehicle: Vehicle, vehicleRef: DocumentReference, context: ModelContext) async throws {
        let localIds = Set((vehicle.documents ?? []).map { $0.id })
        let cloudDocs = try await vehicleRef.collection("documents").getDocuments()

        for doc in cloudDocs.documents {
            guard let documentId = UUID(uuidString: doc.documentID) else { continue }
            if localIds.contains(documentId) { continue }

            let document = decodeDocument(from: doc.data(), id: documentId)
            document.vehicle = vehicle
            context.insert(document)
        }
    }

    // MARK: - Vehicle Encoding / Decoding

    private func encodeVehicle(_ v: Vehicle) -> [String: Any] {
        var data: [String: Any] = [
            "id": v.id.uuidString,
            "name": v.name,
            "make": v.make,
            "model": v.model,
            "year": v.year,
            "currentOdometer": v.currentOdometer,
            "odometerUnit": v.odometerUnit.rawValue,
            "fuelType": v.fuelType.rawValue,
            "isActive": v.isActive,
            "createdAt": Timestamp(date: v.createdAt),
            "updatedAt": Timestamp(date: v.updatedAt),
        ]

        if let vin = v.vin { data["vin"] = vin }
        if let plate = v.licensePlate { data["licensePlate"] = plate }
        if let color = v.color { data["color"] = color }
        if let notes = v.notes { data["notes"] = notes }
        if let purchaseDate = v.purchaseDate { data["purchaseDate"] = Timestamp(date: purchaseDate) }
        if let purchasePrice = v.purchasePrice { data["purchasePrice"] = purchasePrice }
        if let tankCapacity = v.tankCapacity { data["tankCapacity"] = tankCapacity }
        if let insuranceProvider = v.insuranceProvider { data["insuranceProvider"] = insuranceProvider }
        if let policyNumber = v.insurancePolicyNumber { data["insurancePolicyNumber"] = policyNumber }
        if let insExpDate = v.insuranceExpirationDate { data["insuranceExpirationDate"] = Timestamp(date: insExpDate) }
        if let regState = v.registrationState { data["registrationState"] = regState }
        if let regExpDate = v.registrationExpirationDate { data["registrationExpirationDate"] = Timestamp(date: regExpDate) }
        // Skip imageData (binary — use Firebase Storage later)

        return data
    }

    private func decodeVehicle(from data: [String: Any], id: UUID) -> Vehicle {
        let vehicle = Vehicle(
            name: data["name"] as? String ?? "",
            make: data["make"] as? String ?? "",
            model: data["model"] as? String ?? "",
            year: data["year"] as? Int ?? 2024,
            currentOdometer: data["currentOdometer"] as? Double ?? 0,
            odometerUnit: OdometerUnit(rawValue: data["odometerUnit"] as? String ?? "") ?? .kilometers,
            fuelType: FuelType(rawValue: data["fuelType"] as? String ?? "") ?? .petrol
        )
        vehicle.id = id
        vehicle.vin = data["vin"] as? String
        vehicle.licensePlate = data["licensePlate"] as? String
        vehicle.color = data["color"] as? String
        vehicle.notes = data["notes"] as? String
        vehicle.isActive = data["isActive"] as? Bool ?? true
        vehicle.purchaseDate = (data["purchaseDate"] as? Timestamp)?.dateValue()
        vehicle.purchasePrice = data["purchasePrice"] as? Double
        vehicle.tankCapacity = data["tankCapacity"] as? Double
        vehicle.insuranceProvider = data["insuranceProvider"] as? String
        vehicle.insurancePolicyNumber = data["insurancePolicyNumber"] as? String
        vehicle.insuranceExpirationDate = (data["insuranceExpirationDate"] as? Timestamp)?.dateValue()
        vehicle.registrationState = data["registrationState"] as? String
        vehicle.registrationExpirationDate = (data["registrationExpirationDate"] as? Timestamp)?.dateValue()

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            vehicle.createdAt = createdAt
        }
        if let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() {
            vehicle.updatedAt = updatedAt
        }

        return vehicle
    }

    private func updateVehicle(_ v: Vehicle, from data: [String: Any]) {
        v.name = data["name"] as? String ?? v.name
        v.make = data["make"] as? String ?? v.make
        v.model = data["model"] as? String ?? v.model
        v.year = data["year"] as? Int ?? v.year
        v.currentOdometer = data["currentOdometer"] as? Double ?? v.currentOdometer
        if let unit = data["odometerUnit"] as? String, let odometerUnit = OdometerUnit(rawValue: unit) {
            v.odometerUnit = odometerUnit
        }
        if let fuel = data["fuelType"] as? String, let fuelType = FuelType(rawValue: fuel) {
            v.fuelType = fuelType
        }
        v.vin = data["vin"] as? String
        v.licensePlate = data["licensePlate"] as? String
        v.color = data["color"] as? String
        v.notes = data["notes"] as? String
        v.isActive = data["isActive"] as? Bool ?? v.isActive
        v.purchaseDate = (data["purchaseDate"] as? Timestamp)?.dateValue()
        v.purchasePrice = data["purchasePrice"] as? Double
        v.tankCapacity = data["tankCapacity"] as? Double
        v.insuranceProvider = data["insuranceProvider"] as? String
        v.insurancePolicyNumber = data["insurancePolicyNumber"] as? String
        v.insuranceExpirationDate = (data["insuranceExpirationDate"] as? Timestamp)?.dateValue()
        v.registrationState = data["registrationState"] as? String
        v.registrationExpirationDate = (data["registrationExpirationDate"] as? Timestamp)?.dateValue()

        if let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() {
            v.updatedAt = updatedAt
        }
    }

    // MARK: - FuelEntry Encoding / Decoding

    private func encodeFuelEntry(_ e: FuelEntry) -> [String: Any] {
        var data: [String: Any] = [
            "id": e.id.uuidString,
            "date": Timestamp(date: e.date),
            "odometer": e.odometer,
            "quantity": e.quantity,
            "pricePerUnit": e.pricePerUnit,
            "totalCost": e.totalCost,
            "isFullTank": e.isFullTank,
            "fuelGrade": e.fuelGrade.rawValue,
            "createdAt": Timestamp(date: e.createdAt),
        ]

        if let station = e.station { data["station"] = station }
        if let location = e.location { data["location"] = location }
        if let notes = e.notes { data["notes"] = notes }

        return data
    }

    private func decodeFuelEntry(from data: [String: Any], id: UUID) -> FuelEntry {
        let entry = FuelEntry(
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            odometer: data["odometer"] as? Double ?? 0,
            quantity: data["quantity"] as? Double ?? 0,
            pricePerUnit: data["pricePerUnit"] as? Double ?? 0,
            isFullTank: data["isFullTank"] as? Bool ?? true,
            fuelGrade: FuelGrade(rawValue: data["fuelGrade"] as? String ?? "") ?? .regular,
            station: data["station"] as? String,
            location: data["location"] as? String,
            notes: data["notes"] as? String
        )
        entry.id = id

        if let totalCost = data["totalCost"] as? Double {
            entry.totalCost = totalCost
        }
        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            entry.createdAt = createdAt
        }

        return entry
    }

    // MARK: - MaintenanceRecord Encoding / Decoding

    private func encodeMaintenanceRecord(_ r: MaintenanceRecord) -> [String: Any] {
        var data: [String: Any] = [
            "id": r.id.uuidString,
            "date": Timestamp(date: r.date),
            "odometer": r.odometer,
            "serviceType": r.serviceType.rawValue,
            "cost": r.cost,
            "laborCost": r.laborCost,
            "partsCost": r.partsCost,
            "isScheduled": r.isScheduled,
            "createdAt": Timestamp(date: r.createdAt),
        ]

        if let name = r.customServiceName { data["customServiceName"] = name }
        if let provider = r.serviceProvider { data["serviceProvider"] = provider }
        if let phone = r.serviceProviderPhone { data["serviceProviderPhone"] = phone }
        if let address = r.serviceProviderAddress { data["serviceProviderAddress"] = address }
        if let notes = r.notes { data["notes"] = notes }
        if let reminderDate = r.reminderDate { data["reminderDate"] = Timestamp(date: reminderDate) }
        if let reminderOdo = r.reminderOdometer { data["reminderOdometer"] = reminderOdo }
        // Skip receiptImageData (binary)

        return data
    }

    private func decodeMaintenanceRecord(from data: [String: Any], id: UUID) -> MaintenanceRecord {
        let record = MaintenanceRecord(
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            odometer: data["odometer"] as? Double ?? 0,
            serviceType: ServiceType(rawValue: data["serviceType"] as? String ?? "") ?? .custom,
            customServiceName: data["customServiceName"] as? String,
            cost: data["cost"] as? Double ?? 0,
            laborCost: data["laborCost"] as? Double ?? 0,
            partsCost: data["partsCost"] as? Double ?? 0,
            serviceProvider: data["serviceProvider"] as? String,
            notes: data["notes"] as? String
        )
        record.id = id
        record.serviceProviderPhone = data["serviceProviderPhone"] as? String
        record.serviceProviderAddress = data["serviceProviderAddress"] as? String
        record.isScheduled = data["isScheduled"] as? Bool ?? false
        record.reminderDate = (data["reminderDate"] as? Timestamp)?.dateValue()
        record.reminderOdometer = data["reminderOdometer"] as? Double

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            record.createdAt = createdAt
        }

        return record
    }

    // MARK: - MaintenanceSchedule Encoding / Decoding

    private func encodeMaintenanceSchedule(_ s: MaintenanceSchedule) -> [String: Any] {
        var data: [String: Any] = [
            "id": s.id.uuidString,
            "serviceType": s.serviceType.rawValue,
            "isEnabled": s.isEnabled,
            "createdAt": Timestamp(date: s.createdAt),
        ]

        if let name = s.customServiceName { data["customServiceName"] = name }
        if let mileage = s.mileageInterval { data["mileageInterval"] = mileage }
        if let months = s.timeIntervalMonths { data["timeIntervalMonths"] = months }
        if let lastDate = s.lastServiceDate { data["lastServiceDate"] = Timestamp(date: lastDate) }
        if let lastOdo = s.lastServiceOdometer { data["lastServiceOdometer"] = lastOdo }
        if let notes = s.notes { data["notes"] = notes }

        return data
    }

    private func decodeMaintenanceSchedule(from data: [String: Any], id: UUID) -> MaintenanceSchedule {
        let schedule = MaintenanceSchedule(
            serviceType: ServiceType(rawValue: data["serviceType"] as? String ?? "") ?? .custom,
            customServiceName: data["customServiceName"] as? String,
            mileageInterval: data["mileageInterval"] as? Double,
            timeIntervalMonths: data["timeIntervalMonths"] as? Int
        )
        schedule.id = id
        schedule.lastServiceDate = (data["lastServiceDate"] as? Timestamp)?.dateValue()
        schedule.lastServiceOdometer = data["lastServiceOdometer"] as? Double
        schedule.isEnabled = data["isEnabled"] as? Bool ?? true
        schedule.notes = data["notes"] as? String

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            schedule.createdAt = createdAt
        }

        return schedule
    }

    // MARK: - Trip Encoding / Decoding

    private func encodeTrip(_ t: Trip) -> [String: Any] {
        var data: [String: Any] = [
            "id": t.id.uuidString,
            "date": Timestamp(date: t.date),
            "startOdometer": t.startOdometer,
            "tripType": t.tripType.rawValue,
            "isActive": t.isActive,
            "createdAt": Timestamp(date: t.createdAt),
        ]

        if let endOdo = t.endOdometer { data["endOdometer"] = endOdo }
        if let distance = t.distance { data["distance"] = distance }
        if let purpose = t.purpose { data["purpose"] = purpose }
        if let startLoc = t.startLocation { data["startLocation"] = startLoc }
        if let endLoc = t.endLocation { data["endLocation"] = endLoc }
        if let notes = t.notes { data["notes"] = notes }

        return data
    }

    private func decodeTrip(from data: [String: Any], id: UUID) -> Trip {
        let trip = Trip(
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            startOdometer: data["startOdometer"] as? Double ?? 0,
            tripType: TripType(rawValue: data["tripType"] as? String ?? "") ?? .personal,
            purpose: data["purpose"] as? String,
            startLocation: data["startLocation"] as? String
        )
        trip.id = id
        trip.endOdometer = data["endOdometer"] as? Double
        trip.distance = data["distance"] as? Double
        trip.endLocation = data["endLocation"] as? String
        trip.notes = data["notes"] as? String
        trip.isActive = data["isActive"] as? Bool ?? false

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            trip.createdAt = createdAt
        }

        return trip
    }

    // MARK: - Expense Encoding / Decoding

    private func encodeExpense(_ e: Expense) -> [String: Any] {
        var data: [String: Any] = [
            "id": e.id.uuidString,
            "date": Timestamp(date: e.date),
            "category": e.category.rawValue,
            "amount": e.amount,
            "isRecurring": e.isRecurring,
            "createdAt": Timestamp(date: e.createdAt),
        ]

        if let name = e.customCategoryName { data["customCategoryName"] = name }
        if let vendor = e.vendor { data["vendor"] = vendor }
        if let desc = e.expenseDescription { data["expenseDescription"] = desc }
        if let notes = e.notes { data["notes"] = notes }
        if let interval = e.recurringInterval { data["recurringInterval"] = interval.rawValue }
        // Skip receiptImageData (binary)

        return data
    }

    private func decodeExpense(from data: [String: Any], id: UUID) -> Expense {
        let expense = Expense(
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            category: ExpenseCategory(rawValue: data["category"] as? String ?? "") ?? .other,
            customCategoryName: data["customCategoryName"] as? String,
            amount: data["amount"] as? Double ?? 0,
            vendor: data["vendor"] as? String,
            description: data["expenseDescription"] as? String,
            notes: data["notes"] as? String
        )
        expense.id = id
        expense.isRecurring = data["isRecurring"] as? Bool ?? false
        if let interval = data["recurringInterval"] as? String {
            expense.recurringInterval = RecurringInterval(rawValue: interval)
        }

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            expense.createdAt = createdAt
        }

        return expense
    }

    // MARK: - Document Encoding / Decoding

    private func encodeDocument(_ d: Document) -> [String: Any] {
        var data: [String: Any] = [
            "id": d.id.uuidString,
            "name": d.name,
            "documentType": d.documentType.rawValue,
            "createdAt": Timestamp(date: d.createdAt),
            "updatedAt": Timestamp(date: d.updatedAt),
        ]

        if let expDate = d.expirationDate { data["expirationDate"] = Timestamp(date: expDate) }
        if let notes = d.notes { data["notes"] = notes }
        // Skip imageData and pdfData (binary — use Firebase Storage later)

        return data
    }

    private func decodeDocument(from data: [String: Any], id: UUID) -> Document {
        let document = Document(
            name: data["name"] as? String ?? "",
            documentType: DocumentType(rawValue: data["documentType"] as? String ?? "") ?? .other,
            expirationDate: (data["expirationDate"] as? Timestamp)?.dateValue(),
            notes: data["notes"] as? String
        )
        document.id = id

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            document.createdAt = createdAt
        }
        if let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() {
            document.updatedAt = updatedAt
        }

        return document
    }
}
