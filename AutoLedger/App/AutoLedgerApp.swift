import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UserNotifications

// AppDelegate to handle Firebase Auth notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

        // Set notification delegate for Firebase Phone Auth (permission requested during onboarding)
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Handle remote notification registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // Handle incoming remote notifications for Firebase Auth
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }

    // Handle URL for Firebase Auth and Google Sign-In
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct AutoLedgerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let modelContainer: ModelContainer
    @StateObject private var vehicleService = FirebaseVehicleService.shared
    @StateObject private var authService = AuthenticationService()
    @StateObject private var syncService = FirestoreSyncService.shared

    init() {
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
                .environmentObject(authService)
                .environmentObject(syncService)
                .task {
                    // Fetch vehicle makes on app launch
                    if vehicleService.makes.isEmpty || vehicleService.isCacheStale {
                        await vehicleService.fetchMakes()
                    }
                }
                .onOpenURL { url in
                    // Handle Firebase Auth and Google Sign-In URL callbacks
                    if Auth.auth().canHandle(url) {
                        return
                    }
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(modelContainer)
    }
}
