import SwiftUI
import SwiftData

// Firebase temporarily disabled due to SPM resolution issues
// import FirebaseCore

@main
struct AutoLedgerApp: App {
    let modelContainer: ModelContainer
    @StateObject private var vehicleService = FirebaseVehicleService.shared

    init() {
        // Firebase temporarily disabled
        // FirebaseApp.configure()

        // Configure navigation bar appearance for dark mode
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.darkBackground)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.primaryPurple)

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
