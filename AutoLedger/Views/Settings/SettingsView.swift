import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var selectedVehicle: Vehicle?
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage("preferredOdometerUnit") private var odometerUnit = "miles"
    @AppStorage("preferredVolumeUnit") private var volumeUnit = "gallons"
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("maintenanceReminderDays") private var maintenanceReminderDays = 7
    @AppStorage("documentExpirationReminderDays") private var documentExpirationReminderDays = 30
    @State private var userName = ""

    @State private var showingExportOptions = false
    @State private var showingAbout = false
    @State private var showingSignOutConfirmation = false
    @State private var nameSaveTask: Task<Void, Never>?

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
                    Text("Used for Personalized Greetings on the Dashboard")
                        .foregroundColor(.textSecondary.opacity(0.7))
                }

                Section {
                    NavigationLink {
                        VehicleListView(selectedVehicle: $selectedVehicle)
                    } label: {
                        HStack {
                            Image(systemName: "car.2.fill")
                                .foregroundColor(.primaryPurple)
                            Text("Manage Vehicles")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if let vehicle = selectedVehicle {
                                Text(vehicle.displayName)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Vehicles")
                        .foregroundColor(.textSecondary)
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
                    NavigationLink {
                        AISettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.primaryPurple)
                            Text("AI Receipt Scanner")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if KeychainHelper.get(key: "openai_api_key") != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.greenAccent)
                                    .font(.caption)
                            }
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("AI Features")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Enable AI-powered receipt scanning for more accurate auto-fill.")
                        .foregroundColor(.textSecondary.opacity(0.7))
                }

                Section {
                    HStack {
                        GradientAvatarView(
                            uid: authService.user?.uid,
                            name: authService.userProfile?.name,
                            photoURL: authService.userProfile?.photoURL,
                            size: 40
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text({
                            let profileName = authService.userProfile?.name ?? ""
                            return profileName.isEmpty ? (authService.user?.displayName ?? "User") : profileName
                        }())
                                .font(Theme.Typography.headline)
                                .foregroundColor(.textPrimary)

                            Text(authService.user?.email ?? authService.user?.phoneNumber ?? "Signed in")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                    }
                    .darkListRowStyle()

                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                    .darkListRowStyle()
                } header: {
                    Text("Account")
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
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                userName = authService.userProfile?.name ?? ""
            }
            .onChange(of: userName) { _, newValue in
                nameSaveTask?.cancel()
                nameSaveTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                    guard trimmed != authService.userProfile?.name else { return }
                    await authService.updateUserProfile(
                        name: trimmed,
                        email: authService.userProfile?.email,
                        phone: authService.userProfile?.phone
                    )
                }
            }
        }
    }
}

struct BackupSettingsView: View {
    @EnvironmentObject var syncService: FirestoreSyncService
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            // Status section
            Section {
                HStack {
                    Text("Status")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if syncService.isSyncing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.primaryPurple)
                            Text(syncService.syncProgress ?? "Syncing...")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    } else if let lastSync = syncService.lastSyncDate {
                        Text(lastSync.relativeFormatted)
                            .foregroundColor(.greenAccent)
                    } else {
                        Text("Never synced")
                            .foregroundColor(.textSecondary)
                    }
                }
                .darkListRowStyle()

                if let error = syncService.syncError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(Theme.Typography.caption)
                            .foregroundColor(.orange)
                    }
                    .darkListRowStyle()
                }
            } header: {
                Text("Cloud Backup")
                    .foregroundColor(.textSecondary)
            } footer: {
                Text("Your data is backed up to Firebase. Binary data (photos, receipts, PDFs) will be synced in a future update.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }

            // Actions section
            Section {
                Button {
                    Task {
                        await syncService.sync(context: modelContext)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.primaryPurple)
                        Text("Sync Now")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        if syncService.isSyncing {
                            ProgressView()
                                .tint(.primaryPurple)
                        }
                    }
                }
                .disabled(syncService.isSyncing)
                .darkListRowStyle()

                Button {
                    Task {
                        await syncService.backupToCloud(context: modelContext)
                    }
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(.primaryPurple)
                        Text("Back Up to Cloud")
                            .foregroundColor(.textPrimary)
                    }
                }
                .disabled(syncService.isSyncing)
                .darkListRowStyle()

                Button {
                    Task {
                        await syncService.restoreFromCloud(context: modelContext)
                    }
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down")
                            .foregroundColor(.primaryPurple)
                        Text("Restore from Cloud")
                            .foregroundColor(.textPrimary)
                    }
                }
                .disabled(syncService.isSyncing)
                .darkListRowStyle()
            } header: {
                Text("Actions")
                    .foregroundColor(.textSecondary)
            } footer: {
                Text("Sync uploads local data and downloads any missing records from the cloud.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }

            // Danger zone
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete Cloud Data")
                            .foregroundColor(.red)
                    }
                }
                .disabled(syncService.isSyncing)
                .darkListRowStyle()
            } header: {
                Text("Danger Zone")
                    .foregroundColor(.textSecondary)
            } footer: {
                Text("This permanently removes all your data from the cloud. Local data on this device will not be affected.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground)
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("Delete Cloud Data", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete All Cloud Data", role: .destructive) {
                Task {
                    await syncService.deleteCloudData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your vehicle data from the cloud. This action cannot be undone.")
        }
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
                                    .font(Theme.Typography.statValueMedium)
                                    .foregroundColor(.white)
                            }

                            Text("Auto Ledger")
                                .font(Theme.Typography.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            Text("Version \(Bundle.main.appVersionString)")
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.xl)

                        Text("Auto Ledger Helps You Track Fuel Expenses, Maintenance Schedules, Trips, and More for All Your Vehicles.")
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
                                description: "Log Fill-Ups and Track Efficiency",
                                iconColor: .greenAccent
                            )
                            DarkFeatureRow(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Maintenance Management",
                                description: "Schedule and Track Services",
                                iconColor: .primaryPurple
                            )
                            DarkFeatureRow(
                                icon: "map.fill",
                                title: "Trip Logging",
                                description: "Track Business and Personal Trips",
                                iconColor: .pinkAccent
                            )
                            DarkFeatureRow(
                                icon: "chart.bar.fill",
                                title: "Cost Analytics",
                                description: "View Spending Trends",
                                iconColor: .orange
                            )
                            DarkFeatureRow(
                                icon: "icloud.fill",
                                title: "iCloud Sync",
                                description: "Sync Across All Your Devices",
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

struct AISettingsView: View {
    @State private var apiKey: String = ""
    @State private var isKeyVisible = false
    @State private var showingSaved = false

    private var hasExistingKey: Bool {
        KeychainHelper.get(key: "openai_api_key") != nil
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.primaryPurple)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GPT-4o Vision")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.textPrimary)
                        Text("Powered by OpenAI")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if hasExistingKey {
                        Text("Active")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.greenAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.greenAccent.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                .darkListRowStyle()
            } footer: {
                Text("AI Vision uses GPT-4o to read fuel receipts with high accuracy. It handles any receipt format, faded prints, and multiple languages. Falls back to on-device OCR when offline.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }

            Section {
                HStack {
                    if isKeyVisible {
                        TextField("sk-...", text: $apiKey)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        SecureField("sk-...", text: $apiKey)
                            .foregroundColor(.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    Button {
                        isKeyVisible.toggle()
                    } label: {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            .foregroundColor(.textSecondary)
                    }
                }
                .darkListRowStyle()

                Button {
                    if !apiKey.isEmpty {
                        KeychainHelper.save(key: "openai_api_key", value: apiKey)
                    } else {
                        KeychainHelper.delete(key: "openai_api_key")
                    }
                    showingSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingSaved = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.primaryPurple)
                        Text(apiKey.isEmpty ? "Remove Key" : "Save Key")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        if showingSaved {
                            Text("Saved!")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.greenAccent)
                        }
                    }
                }
                .darkListRowStyle()
            } header: {
                Text("OpenAI API Key")
                    .foregroundColor(.textSecondary)
            } footer: {
                Text("Your API key is stored securely in the device Keychain. Get one at platform.openai.com. Cost: ~\u{20B9}1-2 per receipt scan.")
                    .foregroundColor(.textSecondary.opacity(0.7))
            }

            Section {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.greenAccent)
                    Text("Key stored in Keychain")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .darkListRowStyle()

                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.primaryPurple)
                    Text("Falls back to on-device OCR when offline")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                .darkListRowStyle()
            } header: {
                Text("How It Works")
                    .foregroundColor(.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.darkBackground)
        .navigationTitle("AI Receipt Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            // Show masked placeholder if key exists
            if let existing = KeychainHelper.get(key: "openai_api_key") {
                apiKey = existing
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
    SettingsView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
