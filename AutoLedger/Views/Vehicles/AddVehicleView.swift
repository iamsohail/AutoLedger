import SwiftUI
import SwiftData

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vehicleService: FirebaseVehicleService

    // Vehicle Info
    @State private var name = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var currentOdometer = ""
    @State private var odometerUnit: OdometerUnit = .kilometers
    @State private var tankCapacity = ""
    @State private var notes = ""

    // Cascading Selection
    @State private var selectedMake: VehicleMakeData?
    @State private var selectedModel: VehicleModelData?
    @State private var selectedFuelType: FuelType?
    @State private var selectedTransmission: String = "Manual"

    // Manual entry fallback
    @State private var manualMake = ""
    @State private var manualModel = ""
    @State private var manualFuelType: FuelType = .petrol
    @State private var useManualEntry = false

    // Validation
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    private let currentYear = Calendar.current.component(.year, from: Date())

    private var yearRange: [Int] {
        Array((2000...(currentYear + 1)).reversed())
    }

    // MARK: - Computed Properties

    private var availableModels: [VehicleModelData] {
        guard let make = selectedMake else { return [] }
        return make.models.filter { !$0.isDiscontinued }
    }

    private var availableFuelTypes: [FuelType] {
        guard let model = selectedModel else { return [] }
        return model.availableFuelTypes
    }

    private var availableTransmissions: [String] {
        guard let model = selectedModel else { return ["Manual"] }
        return model.transmissionOptions
    }

    private var showTransmissionPicker: Bool {
        selectedModel?.hasBothTransmissions ?? false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Car Preview Section (shows when make & model selected)
                        if selectedMake != nil && selectedModel != nil {
                            carPreviewSection
                        }

                        // Vehicle Selection Section
                        vehicleSelectionSection

                        // Vehicle Details Section
                        vehicleDetailsSection

                        // Specifications Section
                        specificationsSection

                        // Notes Section
                        notesSection

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveVehicle() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isValid ? .primaryPurple : .textSecondary.opacity(0.5))
                        .disabled(!isValid)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
            .task {
                if vehicleService.makes.isEmpty {
                    await vehicleService.fetchMakes()
                }
            }
        }
    }

    // MARK: - Car Preview Section

    private var carPreviewSection: some View {
        VStack(spacing: 16) {
            if let make = selectedMake, let model = selectedModel {
                // Show bundled car image or placeholder
                CarImageView(
                    make: make.name,
                    model: model.name,
                    size: 200,
                    cornerRadius: 20
                )

                // Vehicle name
                Text("\(year) \(make.name) \(model.name)")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - Vehicle Selection Section

    private var vehicleSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            Text("Select Vehicle")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                if useManualEntry {
                    manualEntryFields
                } else {
                    // Make Selection Card with Logo
                    makeSelectionCard

                    // Model Picker
                    if selectedMake != nil {
                        selectionRow(
                            title: "Model",
                            value: selectedModel?.name ?? "Select Model",
                            isSelected: selectedModel != nil
                        ) {
                            Button("Select Model") { selectedModel = nil }
                            ForEach(availableModels) { model in
                                Button(model.name) { selectedModel = model }
                            }
                        }
                        .onChange(of: selectedModel) { _, newModel in
                            selectedFuelType = nil
                            if let model = newModel {
                                let fuelTypes = model.availableFuelTypes
                                if fuelTypes.count == 1 {
                                    selectedFuelType = fuelTypes.first
                                }
                                if !model.hasBothTransmissions {
                                    selectedTransmission = model.transmission
                                }
                                autoFillCapacity(from: model)
                            }
                        }
                    }

                    // Fuel Type Picker
                    if selectedModel != nil {
                        selectionRow(
                            title: "Fuel Type",
                            value: selectedFuelType?.rawValue ?? "Select Fuel",
                            isSelected: selectedFuelType != nil
                        ) {
                            Button("Select Fuel") { selectedFuelType = nil }
                            ForEach(availableFuelTypes, id: \.self) { fuelType in
                                Button(fuelType.rawValue) { selectedFuelType = fuelType }
                            }
                        }
                        .onChange(of: selectedFuelType) { _, _ in
                            if let model = selectedModel {
                                autoFillCapacity(from: model)
                            }
                        }
                    }

                    // Transmission Picker
                    if showTransmissionPicker {
                        selectionRow(
                            title: "Transmission",
                            value: selectedTransmission,
                            isSelected: true
                        ) {
                            ForEach(availableTransmissions, id: \.self) { transmission in
                                Button(transmission) { selectedTransmission = transmission }
                            }
                        }
                    }
                }

                // Manual Entry Toggle
                HStack {
                    Text("Enter Manually")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Toggle("", isOn: $useManualEntry)
                        .labelsHidden()
                        .tint(.primaryPurple)
                }
                .padding(16)
                .background(Color.cardBackground)
                .cornerRadius(14)
            }

            // Error message
            if let error = vehicleService.error {
                Text(error)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
            }
        }
    }

    // MARK: - Make Selection Card

    private var makeSelectionCard: some View {
        Menu {
            Button("Select Make") { selectedMake = nil }
            Divider()
            // Popular makes first
            let popularMakes = ["Maruti", "Hyundai", "Tata", "Mahindra", "Toyota", "Honda", "Kia"]
            let popular = vehicleService.makes.filter { popularMakes.contains($0.name) }
            let others = vehicleService.makes.filter { !popularMakes.contains($0.name) }

            if !popular.isEmpty {
                Section("Popular") {
                    ForEach(popular) { make in
                        Button(make.name) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMake = make
                            }
                        }
                    }
                }
            }
            if !others.isEmpty {
                Section("All Brands") {
                    ForEach(others) { make in
                        Button(make.name) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMake = make
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 16) {
                // Brand Logo (no box, just the logo)
                if let make = selectedMake {
                    BrandLogoView(make: make.name, size: 44, fallbackColor: .primaryPurple)
                } else {
                    Image(systemName: "car.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.textSecondary.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Make")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)

                    HStack {
                        Text(selectedMake?.name ?? "Select Make")
                            .font(Theme.Typography.bodyMedium)
                            .foregroundColor(selectedMake != nil ? .textPrimary : .textSecondary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }

                if vehicleService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
        .onChange(of: selectedMake) { _, _ in
            selectedModel = nil
            selectedFuelType = nil
            selectedTransmission = "Manual"
            tankCapacity = ""
        }
    }

    // MARK: - Vehicle Details Section

    private var vehicleDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Details")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Nickname
                inputField(placeholder: "Nickname (Optional)", text: $name)

                dividerLine

                // Year
                HStack {
                    Text("Year")
                        .font(Theme.Typography.body)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Menu {
                        ForEach(yearRange, id: \.self) { yr in
                            Button(String(yr)) { year = yr }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(String(year))
                                .foregroundColor(.primaryPurple)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primaryPurple)
                        }
                        .font(Theme.Typography.bodyMedium)
                    }
                }
                .padding(16)

                dividerLine

                // VIN
                inputField(placeholder: "VIN (Optional)", text: $vin)

                dividerLine

                // License Plate
                inputField(placeholder: "License Plate (Optional)", text: $licensePlate)
            }
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    // MARK: - Specifications Section

    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specifications")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Odometer
                HStack {
                    TextField("Current Odometer", text: $currentOdometer)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.textPrimary)

                    Picker("", selection: $odometerUnit) {
                        ForEach(OdometerUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }
                .padding(16)

                dividerLine

                // Tank/Battery Capacity
                HStack {
                    TextField(tankCapacityLabel, text: $tankCapacity)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.textPrimary)

                    if !tankCapacity.isEmpty {
                        Text(capacityUnit)
                            .font(Theme.Typography.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(16)
            }
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            TextEditor(text: $notes)
                .foregroundColor(.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(14)
        }
    }

    // MARK: - Reusable Components

    private var dividerLine: some View {
        Divider()
            .background(Color.textSecondary.opacity(0.15))
            .padding(.horizontal, 16)
    }

    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.textSecondary.opacity(0.5)))
            .foregroundColor(.textPrimary)
            .padding(16)
    }

    private func selectionRow<Content: View>(
        title: String,
        value: String,
        isSelected: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Text(value)
                        .foregroundColor(isSelected ? .primaryPurple : .textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isSelected ? .primaryPurple : .textSecondary)
                }
                .font(Theme.Typography.body)
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    private var manualEntryFields: some View {
        VStack(spacing: 0) {
            inputField(placeholder: "Make", text: $manualMake)
            dividerLine
            inputField(placeholder: "Model", text: $manualModel)
            dividerLine

            // Fuel Type
            HStack {
                Text("Fuel Type")
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                Menu {
                    ForEach(FuelType.allCases, id: \.self) { type in
                        Button(type.rawValue) { manualFuelType = type }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(manualFuelType.rawValue)
                            .foregroundColor(.primaryPurple)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primaryPurple)
                    }
                    .font(Theme.Typography.body)
                }
            }
            .padding(16)

            dividerLine

            // Transmission
            HStack {
                Text("Transmission")
                    .font(Theme.Typography.body)
                    .foregroundColor(.textPrimary)

                Spacer()

                Menu {
                    Button("Manual") { selectedTransmission = "Manual" }
                    Button("Automatic") { selectedTransmission = "Automatic" }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedTransmission)
                            .foregroundColor(.primaryPurple)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primaryPurple)
                    }
                    .font(Theme.Typography.body)
                }
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Helper Properties

    private var tankCapacityLabel: String {
        let fuelType = useManualEntry ? manualFuelType : (selectedFuelType ?? .petrol)
        return fuelType == .electric ? "Battery Capacity" : "Tank Capacity"
    }

    private var capacityUnit: String {
        let fuelType = useManualEntry ? manualFuelType : (selectedFuelType ?? .petrol)
        return fuelType == .electric ? "kWh" : "L"
    }

    // MARK: - Helper Methods

    private func autoFillCapacity(from model: VehicleModelData) {
        guard tankCapacity.isEmpty else { return }

        let fuelType = selectedFuelType ?? .petrol

        if fuelType == .electric, let battery = model.batteryCapacity {
            tankCapacity = String(format: "%.1f", battery)
        } else if let tank = model.tankCapacity {
            tankCapacity = String(format: "%.0f", tank)
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        if useManualEntry {
            return !manualMake.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !manualModel.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return selectedMake != nil &&
                   selectedModel != nil &&
                   selectedFuelType != nil
        }
    }

    private var finalMake: String {
        useManualEntry ? manualMake.trimmingCharacters(in: .whitespaces) : (selectedMake?.name ?? "")
    }

    private var finalModel: String {
        useManualEntry ? manualModel.trimmingCharacters(in: .whitespaces) : (selectedModel?.name ?? "")
    }

    private var finalFuelType: FuelType {
        useManualEntry ? manualFuelType : (selectedFuelType ?? .petrol)
    }

    // MARK: - Save

    private func saveVehicle() {
        guard isValid else {
            validationErrorMessage = "Please Select Make, Model, and Fuel Type."
            showingValidationError = true
            return
        }

        let vehicle = Vehicle(
            name: name.trimmingCharacters(in: .whitespaces),
            make: finalMake,
            model: finalModel,
            year: year,
            currentOdometer: Double(currentOdometer) ?? 0,
            odometerUnit: odometerUnit,
            fuelType: finalFuelType
        )

        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate
        vehicle.tankCapacity = Double(tankCapacity)
        vehicle.notes = notes.isEmpty ? nil : notes

        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .environmentObject(FirebaseVehicleService.shared)
        .modelContainer(for: Vehicle.self, inMemory: true)
}
