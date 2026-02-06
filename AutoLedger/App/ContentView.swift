import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @Query(filter: #Predicate<Vehicle> { $0.isActive }, sort: \Vehicle.createdAt, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var selectedTab: Tab = .dashboard
    @State private var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case vehicles = "Vehicles"
        case fuel = "Fuel"
        case maintenance = "Maintenance"
        case trips = "Trips"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "gauge.with.dots.needle.33percent"
            case .vehicles: return "car.2.fill"
            case .fuel: return "fuelpump.fill"
            case .maintenance: return "wrench.and.screwdriver.fill"
            case .trips: return "map.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    init() {
        // Configure tab bar appearance for dark mode
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.darkBackground)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textSecondary)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryPurple)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.primaryPurple)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                // Step 1: First-time users see feature showcase
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                })
            } else if authService.isCheckingAuth {
                // Wait for Firebase to restore session before showing login
                splashView
            } else if !authService.isAuthenticated {
                // Step 2: Login
                SignInView()
            } else if authService.needsProfileCompletion {
                // Step 3: Complete profile if needed
                ProfileCompletionView()
            } else if vehicles.isEmpty {
                // Step 4: No vehicles - show add vehicle prompt
                emptyVehicleState
            } else {
                // Step 5: Main app
                mainTabView
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleView()
        }
        .onAppear {
            if selectedVehicle == nil {
                selectedVehicle = vehicles.first
            }
        }
        .preferredColorScheme(.dark)
    }

    private var splashView: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            CarLoadingView(size: 52)
        }
    }

    private var emptyVehicleState: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "car.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryPurple.opacity(0.5))

                Text("No Vehicles Yet")
                    .font(Theme.Typography.title)
                    .foregroundColor(.textPrimary)

                Text("Add your first vehicle to start tracking fuel, maintenance, and trips.")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    showingAddVehicle = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Vehicle")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.primaryPurple)
                    .cornerRadius(12)
                }
                .padding(.top, 16)
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            VehicleListView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.vehicles.rawValue, systemImage: Tab.vehicles.icon)
                }
                .tag(Tab.vehicles)

            FuelLogView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.fuel.rawValue, systemImage: Tab.fuel.icon)
                }
                .tag(Tab.fuel)

            MaintenanceListView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.maintenance.rawValue, systemImage: Tab.maintenance.icon)
                }
                .tag(Tab.maintenance)

            TripListView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.trips.rawValue, systemImage: Tab.trips.icon)
                }
                .tag(Tab.trips)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
