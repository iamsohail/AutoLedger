import SwiftUI
import SwiftData

@main
struct AutoLedgerApp: App {
    let modelContainer: ModelContainer

    init() {
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
        }
        .modelContainer(modelContainer)
    }
}
