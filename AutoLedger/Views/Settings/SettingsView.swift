import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("preferredOdometerUnit") private var odometerUnit = "miles"
    @AppStorage("preferredVolumeUnit") private var volumeUnit = "gallons"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("maintenanceReminderDays") private var maintenanceReminderDays = 7
    @AppStorage("documentExpirationReminderDays") private var documentExpirationReminderDays = 30

    @State private var showingExportOptions = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            List {
                Section("Units") {
                    Picker("Distance", selection: $odometerUnit) {
                        Text("Miles").tag("miles")
                        Text("Kilometers").tag("km")
                    }

                    Picker("Volume", selection: $volumeUnit) {
                        Text("Gallons").tag("gallons")
                        Text("Liters").tag("liters")
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $enableNotifications)

                    if enableNotifications {
                        Stepper("Maintenance reminder: \(maintenanceReminderDays) days before", value: $maintenanceReminderDays, in: 1...30)

                        Stepper("Document expiration: \(documentExpirationReminderDays) days before", value: $documentExpirationReminderDays, in: 7...90)
                    }
                }

                Section("Data") {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        BackupSettingsView()
                    } label: {
                        Label("Backup & Sync", systemImage: "icloud")
                    }
                }

                Section("About") {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text("About Auto Ledger")
                            Spacer()
                            Text(Bundle.main.appVersionString)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Link(destination: URL(string: "https://apple.com")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://apple.com")!) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                }
            }
            .navigationTitle("Settings")
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
            } footer: {
                Text("When enabled, your data will automatically sync across all your devices signed into the same iCloud account.")
            }

            Section("Last Sync") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text("Up to date")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.inline)
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
                Section("Vehicle") {
                    Picker("Select Vehicle", selection: $selectedVehicle) {
                        Text("All Vehicles").tag(nil as Vehicle?)
                        ForEach(vehicles) { vehicle in
                            Text(vehicle.displayName).tag(vehicle as Vehicle?)
                        }
                    }
                }

                Section("Export Options") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Data Type", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section {
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Export", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Auto Ledger")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Version \(Bundle.main.appVersionString)")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)

                Section {
                    Text("Auto Ledger helps you track fuel expenses, maintenance schedules, trips, and more for all your vehicles.")
                        .font(.body)
                }

                Section("Features") {
                    FeatureListItem(icon: "fuelpump.fill", title: "Fuel Tracking", color: .orange)
                    FeatureListItem(icon: "wrench.and.screwdriver.fill", title: "Maintenance Management", color: .blue)
                    FeatureListItem(icon: "map.fill", title: "Trip Logging", color: .green)
                    FeatureListItem(icon: "chart.bar.fill", title: "Cost Analytics", color: .purple)
                    FeatureListItem(icon: "icloud.fill", title: "iCloud Sync", color: .cyan)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureListItem: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
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
