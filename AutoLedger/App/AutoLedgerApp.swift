import SwiftUI
import SwiftData
import FirebaseCore

@main
struct AutoLedgerApp: App {
    let modelContainer: ModelContainer
    @StateObject private var vehicleService = FirebaseVehicleService.shared

    init() {
        // Initialize Firebase
        FirebaseApp.configure()

        do {
            let schema = Schema([
                Vehicle.self,
                FuelEntry.self,
                MaintenanceRecord.self,
                MaintenanceSchedule.self,
                Trip.self,
                Expense.self,
                Document.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vehicleService)
                .task {
                    // Fetch vehicle makes on app launch
                    if vehicleService.makes.isEmpty || vehicleService.isCacheStale {
                        await vehicleService.fetchMakes()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
