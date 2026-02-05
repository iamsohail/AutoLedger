import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("preferredOdometerUnit") private var odometerUnit = "miles"
    @AppStorage("preferredVolumeUnit") private var volumeUnit = "gallons"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("maintenanceReminderDays") private var maintenanceReminderDays = 7
    @AppStorage("documentExpirationReminderDays") private var documentExpirationReminderDays = 30
    @AppStorage("userName") private var userName = ""

    @State private var showingExportOptions = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Name")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        TextField("Your name", text: $userName)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Profile")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Used for personalized greetings on the dashboard")
                        .foregroundColor(.textSecondary.opacity(0.7))
                }

                Section {
                    Picker("Distance", selection: $odometerUnit) {
                        Text("Miles").tag("miles")
                        Text("Kilometers").tag("km")
                    }
                    .darkListRowStyle()

                    Picker("Volume", selection: $volumeUnit) {
                        Text("Gallons").tag("gallons")
                        Text("Liters").tag("liters")
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Units")
                        .foregroundColor(.textSecondary)
                }

                Section {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                        .tint(.primaryPurple)
                        .darkListRowStyle()

                    if enableNotifications {
                        Stepper("Maintenance reminder: \(maintenanceReminderDays) days before", value: $maintenanceReminderDays, in: 1...30)
                            .darkListRowStyle()

                        Stepper("Document expiration: \(documentExpirationReminderDays) days before", value: $documentExpirationReminderDays, in: 7...90)
                            .darkListRowStyle()
                    }
                } header: {
                    Text("Notifications")
                        .foregroundColor(.textSecondary)
                }

                Section {
                    Button {
                        showingExportOptions = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.primaryPurple)
                            Text("Export Data")
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .darkListRowStyle()

                    NavigationLink {
                        BackupSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(.primaryPurple)
                            Text("Backup & Sync")
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Data")
                        .foregroundColor(.textSecondary)
                }

                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text("About Auto Ledger")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text(Bundle.main.appVersionString)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .darkListRowStyle()

                    Link(destination: URL(string: "https://apple.com")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.primaryPurple)
                            Text("Privacy Policy")
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .darkListRowStyle()

                    Link(destination: URL(string: "https://apple.com")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.primaryPurple)
                            Text("Terms of Service")
                                .foregroundColor(.textPrimary)
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("About")
                        .foregroundColor(.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .navigationTitle("Settings")
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct BackupSettingsView: View {
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true

    var body: some View {
        List {
            Section {
                Toggle("iCloud Sync", isOn: $iCloudSyncEnabled)
                    .tint(.primaryPurple)
                    .darkListRowStyle()
            } footer: {
                Text("When enabled, your data will automatically sync across all your devices signed into the same iCloud account.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }

            Section {
                HStack {
                    Text("Status")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("Up to date")
                        .foregroundColor(.greenAccent)
                }
                .darkListRowStyle()
            } header: {
                Text("Last Sync")
                    .foregroundColor(.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground)
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]

    @State private var selectedVehicle: Vehicle?
    @State private var exportFormat: ExportFormat = .csv
    @State private var exportType: ExportType = .all

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }

    enum ExportType: String, CaseIterable {
        case all = "All Data"
        case fuel = "Fuel Only"
        case maintenance = "Maintenance Only"
        case trips = "Trips Only"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Select Vehicle", selection: $selectedVehicle) {
                        Text("All Vehicles").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Vehicle")
                        .foregroundColor(.textSecondary)
                }

                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .darkListRowStyle()

                    Picker("Data Type", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Export Options")
                        .foregroundColor(.textSecondary)
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                            Spacer()
                        }
                        .foregroundColor(.white)
                    }
                    .listRowBackground(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.pinkAccent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
        }
    }

    private func exportData() {
        // Export implementation would go here
        dismiss()
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // App icon
                        VStack(spacing: Theme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.primaryPurple, Color.pinkAccent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.primaryPurple.opacity(0.5), radius: 15, x: 0, y: 8)

                                Image(systemName: "car.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }

                            Text("Auto Ledger")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Version \(Bundle.main.appVersionString)")
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.xl)

                        Text("Auto Ledger helps you track fuel expenses, maintenance schedules, trips, and more for all your vehicles.")
                            .font(Theme.Typography.cardSubtitle)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.lg)

                        // Features
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Features")
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.bottom, Theme.Spacing.xs)

                            DarkFeatureRow(
                                icon: "fuelpump.fill",
                                title: "Fuel Tracking",
                                description: "Log fill-ups and track efficiency",
                                iconColor: .greenAccent
                            )
                            DarkFeatureRow(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Maintenance Management",
                                description: "Schedule and track services",
                                iconColor: .primaryPurple
                            )
                            DarkFeatureRow(
                                icon: "map.fill",
                                title: "Trip Logging",
                                description: "Track business and personal trips",
                                iconColor: .pinkAccent
                            )
                            DarkFeatureRow(
                                icon: "chart.bar.fill",
                                title: "Cost Analytics",
                                description: "View spending trends",
                                iconColor: .orange
                            )
                            DarkFeatureRow(
                                icon: "icloud.fill",
                                title: "iCloud Sync",
                                description: "Sync across all your devices",
                                iconColor: .cyan
                            )
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPurple)
                }
            }
        }
    }
}

extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
