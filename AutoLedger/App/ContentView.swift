import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @Query(filter: #Predicate<Vehicle> { $0.isActive }, sort: \Vehicle.createdAt, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var selectedTab: Tab = .home
    @State private var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false
    @State private var showingFirstVehicle = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    enum Tab: String, CaseIterable {
        case home = "Home"
        case log = "Log"
        case explore = "Explore"
        case vault = "Vault"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .log: return "list.bullet.clipboard.fill"
            case .explore: return "map.fill"
            case .vault: return "folder.fill"
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
            if authService.isCheckingAuth {
                // Step 1: Wait for Firebase to restore session
                splashView
            } else if !authService.isAuthenticated {
                // Step 2: Login
                SignInView()
            } else if authService.needsProfileCompletion {
                // Step 3: Complete profile if needed
                ProfileCompletionView()
            } else if !hasSeenOnboarding {
                // Step 4: Feature showcase (shown once after first sign-in)
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                    showingFirstVehicle = true
                })
            } else if vehicles.isEmpty {
                // Step 5: No vehicles - show add vehicle prompt
                emptyVehicleState
            } else {
                // Step 6: Main app
                mainTabView
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleView()
        }
        .fullScreenCover(isPresented: $showingFirstVehicle) {
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
            GradientSpinner(size: 48)
        }
    }

    private var displayName: String {
        let name = authService.userProfile?.name ?? ""
        return name.isEmpty ? "there" : name.components(separatedBy: " ").first ?? name
    }

    private var emptyVehicleState: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer()

                // Welcome text
                Text("Hey \(displayName)!")
                    .font(Theme.Typography.title)
                    .foregroundColor(.textSecondary)

                // Icon with gradient glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.primaryPurple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "car.fill")
                        .font(Theme.Typography.statValue)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primaryPurple, .pinkAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .repeating)
                }

                VStack(spacing: Theme.Spacing.sm) {
                    Text("No Vehicles Yet")
                        .font(Theme.Typography.title)
                        .foregroundColor(.textPrimary)

                    Text("Add Your First Vehicle to Start Tracking\nFuel, Maintenance, and Trips.")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Feature chips
                HStack(spacing: Theme.Spacing.sm) {
                    featureChip(icon: "fuelpump.fill", label: "Fuel", color: .greenAccent)
                    featureChip(icon: "wrench.fill", label: "Service", color: .orange)
                    featureChip(icon: "location.fill", label: "Trips", color: .primaryPurple)
                    featureChip(icon: "doc.text.fill", label: "Docs", color: Color(hex: "00BCD4"))
                }
                .padding(.top, Theme.Spacing.xs)

                // Gradient CTA button
                Button {
                    showingAddVehicle = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Vehicle")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [.primaryPurple, .pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                .padding(.horizontal, 40)
                .padding(.top, Theme.Spacing.sm)

                Spacer()
                Spacer()
            }
        }
    }

    private func featureChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(Theme.Typography.caption2)
                .foregroundColor(color)
            Text(label)
                .font(Theme.Typography.captionMedium)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, Theme.Spacing.sm + 4)
        .padding(.vertical, Theme.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.pill)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            LogView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.log.rawValue, systemImage: Tab.log.icon)
                }
                .tag(Tab.log)

            ExploreView()
                .tabItem {
                    Label(Tab.explore.rawValue, systemImage: Tab.explore.icon)
                }
                .tag(Tab.explore)

            VaultView(selectedVehicle: $selectedVehicle)
                .tabItem {
                    Label(Tab.vault.rawValue, systemImage: Tab.vault.icon)
                }
                .tag(Tab.vault)

            SettingsView(selectedVehicle: $selectedVehicle)
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
