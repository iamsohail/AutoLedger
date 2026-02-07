import SwiftUI
import SwiftData

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vehicleService: FirebaseVehicleService

    // MARK: - Step Management

    enum Step: Int, CaseIterable {
        case brand = 0
        case model = 1
        case details = 2
    }

    @State private var currentStep: Step = .brand

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
    @State private var modelSearch = ""

    // Manual entry fallback
    @State private var manualMake = ""
    @State private var manualModel = ""
    @State private var manualFuelType: FuelType = .petrol
    @State private var useManualEntry = false

    // UI State
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var brandSearch = ""

    private let currentYear = Calendar.current.component(.year, from: Date())
    private let popularMakeNames = ["Maruti Suzuki", "Hyundai", "Tata", "Mahindra", "Toyota", "Honda", "Kia"]

    // MARK: - Computed Properties

    private var yearRange: [Int] {
        Array((2000...(currentYear + 1)).reversed())
    }

    private var availableModels: [VehicleModelData] {
        guard let make = selectedMake else { return [] }
        if modelSearch.isEmpty { return make.models }
        return make.models.filter { $0.name.localizedCaseInsensitiveContains(modelSearch) }
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

    private var filteredMakes: [VehicleMakeData] {
        if brandSearch.isEmpty { return vehicleService.makes }
        return vehicleService.makes.filter { $0.name.localizedCaseInsensitiveContains(brandSearch) }
    }

    private var popularMakes: [VehicleMakeData] {
        filteredMakes.filter { popularMakeNames.contains($0.name) }
    }

    private var otherMakes: [VehicleMakeData] {
        filteredMakes.filter { !popularMakeNames.contains($0.name) }
    }

    private var navigationTitle: String {
        switch currentStep {
        case .brand: return "Add Vehicle"
        case .model: return selectedMake?.name ?? "Select Model"
        case .details: return "Vehicle Details"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                switch currentStep {
                case .brand:
                    brandSelectionView
                case .model:
                    modelSelectionView
                case .details:
                    detailsFormView
                }
            }
            .navigationTitle(currentStep == .model ? "" : navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == .brand {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.textSecondary)
                    } else {
                        Button {
                            goBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    if currentStep == .model, let make = selectedMake {
                        BrandLogoView(make: make.name, size: 56, fallbackColor: .primaryPurple)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .details {
                        Button("Save") { saveVehicle() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isValid ? .primaryPurple : .textSecondary.opacity(0.5))
                            .disabled(!isValid)
                    }
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

    // MARK: - Step 1: Brand Selection

    private var brandSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)

                    TextField("", text: $brandSearch, prompt: Text("Search brands...").foregroundColor(.textSecondary.opacity(0.5)))
                        .foregroundColor(.textPrimary)
                        .autocorrectionDisabled()
                }
                .padding(14)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if vehicleService.isLoading {
                    Spacer().frame(height: 100)
                    GradientSpinner(size: 36)
                    Spacer()
                } else {
                    // Popular Brands
                    if !popularMakes.isEmpty && brandSearch.isEmpty {
                        brandSection(title: "Popular Brands", makes: popularMakes)
                    }

                    // All/Other Brands
                    brandSection(
                        title: brandSearch.isEmpty ? "All Brands" : "Results",
                        makes: brandSearch.isEmpty ? otherMakes : filteredMakes
                    )

                    // Manual Entry link
                    Button {
                        useManualEntry = true
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .details
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                            Text("Enter Manually Instead")
                                .font(Theme.Typography.subheadline)
                        }
                        .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }

                if let error = vehicleService.error {
                    Text(error)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
            }
        }
    }

    private func brandSection(title: String, makes: [VehicleMakeData]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Theme.Typography.subheadlineMedium)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 20)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                spacing: 20
            ) {
                ForEach(makes) { make in
                    brandTile(make)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func brandTile(_ make: VehicleMakeData) -> some View {
        Button {
            selectedMake = make
            selectedModel = nil
            selectedFuelType = nil
            selectedTransmission = "Manual"
            tankCapacity = ""
            brandSearch = ""
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .model
            }
        } label: {
            VStack(spacing: 10) {
                BrandLogoView(make: make.name, size: 56, fallbackColor: .primaryPurple)
                    .shadow(color: .primaryPurple.opacity(0.15), radius: 8, y: 2)

                Text(make.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    // MARK: - Step 2: Model Selection

    private var modelSelectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.md) {
                // Search bar
                if let make = selectedMake, make.models.count > 6 {
                    HStack(spacing: Theme.Spacing.sm + 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)

                        TextField("", text: $modelSearch, prompt: Text("Search models...").foregroundColor(.textSecondary.opacity(0.5)))
                            .foregroundColor(.textPrimary)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .background(Color.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, 20)
                    .padding(.top, Theme.Spacing.xs)
                }

                // Model count
                HStack {
                    Text("\(availableModels.count) models")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Model grid (2 columns)
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm + 4), GridItem(.flexible(), spacing: Theme.Spacing.sm + 4)],
                    spacing: Theme.Spacing.sm + 4
                ) {
                    ForEach(availableModels) { model in
                        modelCard(model)
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)
            }
        }
    }

    private func modelCard(_ model: VehicleModelData) -> some View {
        Button {
            selectedModel = model
            selectedFuelType = nil
            modelSearch = ""
            let fuelTypes = model.availableFuelTypes
            if fuelTypes.count == 1 {
                selectedFuelType = fuelTypes.first
            }
            if !model.hasBothTransmissions {
                selectedTransmission = model.transmission
            }
            autoFillCapacity(from: model)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .details
            }
        } label: {
            VStack(spacing: Theme.Spacing.xs + 2) {
                CarImageView(
                    make: selectedMake?.name ?? "",
                    model: model.name,
                    size: 120,
                    cornerRadius: Theme.CornerRadius.medium
                )
                .frame(maxWidth: .infinity)

                Text(model.name)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private func fuelShortName(_ fuel: FuelType) -> String {
        switch fuel {
        case .petrol, .gasoline: return "Petrol"
        case .diesel: return "Diesel"
        case .cng: return "CNG"
        case .electric: return "EV"
        case .hybrid: return "Hybrid"
        case .plugInHybrid: return "PHEV"
        case .hydrogen: return "H\u{2082}"
        case .flexFuel: return "Flex"
        }
    }

    private func fuelChipColor(_ fuel: FuelType) -> Color {
        switch fuel {
        case .petrol, .gasoline: return .greenAccent
        case .diesel: return .orange
        case .cng: return Color(hex: "00BCD4")
        case .electric: return .primaryPurple
        case .hybrid, .plugInHybrid: return Color(hex: "4FC3F7")
        case .hydrogen: return Color(hex: "26C6DA")
        case .flexFuel: return .yellow
        }
    }

    // MARK: - Step 3: Details Form

    private var detailsFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if useManualEntry {
                    manualEntryCard
                } else {
                    // Hero section
                    heroSection

                    // Configuration card (fuel, transmission, year)
                    configurationCard
                }

                // Vehicle details card
                vehicleDetailsCard

                // Specifications card
                specificationsCard

                // Notes card
                notesCard

                // Save button
                saveButton

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            if let make = selectedMake, let model = selectedModel {
                CarImageView(
                    make: make.name,
                    model: model.name,
                    size: 200,
                    cornerRadius: 20
                )

                Text("\(String(year)) \(make.name) \(model.name)")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Fuel Type chips (only if multiple options)
                if availableFuelTypes.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fuel Type")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: 8) {
                            ForEach(availableFuelTypes, id: \.self) { fuel in
                                fuelChip(fuel)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)

                    dividerLine
                }

                // Transmission toggle
                if showTransmissionPicker {
                    HStack {
                        Text("Transmission")
                            .font(Theme.Typography.body)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        HStack(spacing: 0) {
                            ForEach(availableTransmissions, id: \.self) { trans in
                                Button {
                                    selectedTransmission = trans
                                } label: {
                                    Text(trans)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedTransmission == trans ? .white : .textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedTransmission == trans ? Color.primaryPurple : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .background(Color.darkBackground)
                        .cornerRadius(8)
                    }
                    .padding(16)

                    dividerLine
                }

                // Year
                yearRow
            }
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    private func fuelChip(_ fuel: FuelType) -> some View {
        Button {
            selectedFuelType = fuel
            if let model = selectedModel {
                autoFillCapacity(from: model)
            }
        } label: {
            Text(fuel.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(selectedFuelType == fuel ? .white : .textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selectedFuelType == fuel ? Color.primaryPurple : Color.darkBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedFuelType == fuel ? Color.clear : Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var yearRow: some View {
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
    }

    private var vehicleDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Details")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                inputField(placeholder: "Nickname (Optional)", text: $name)
                dividerLine
                inputField(placeholder: "License Plate (Optional)", text: $licensePlate)
                dividerLine
                inputField(placeholder: "VIN (Optional)", text: $vin)
            }
            .background(Color.cardBackground)
            .cornerRadius(14)
        }
    }

    private var specificationsCard: some View {
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

    private var notesCard: some View {
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

    private var saveButton: some View {
        Button {
            saveVehicle()
        } label: {
            Text("Save Vehicle")
                .font(Theme.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.primaryPurple, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(isValid ? 1 : 0.5)
                )
                .cornerRadius(14)
        }
        .disabled(!isValid)
    }

    // MARK: - Manual Entry Card

    private var manualEntryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Info")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

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

                dividerLine

                yearRow
            }
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

    // MARK: - Navigation

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .brand:
                break
            case .model:
                modelSearch = ""
                currentStep = .brand
            case .details:
                if useManualEntry {
                    useManualEntry = false
                    currentStep = .brand
                } else {
                    currentStep = .model
                }
            }
        }
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

// MARK: - Array Dedup Helper

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    AddVehicleView()
        .environmentObject(FirebaseVehicleService.shared)
        .modelContainer(for: Vehicle.self, inMemory: true)
}
