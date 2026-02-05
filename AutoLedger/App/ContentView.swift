import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Vehicle> { $0.isActive }, sort: \Vehicle.createdAt, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var selectedTab: Tab = .dashboard
    @State private var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false

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
            if vehicles.isEmpty {
                OnboardingView(showingAddVehicle: $showingAddVehicle)
            } else {
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
