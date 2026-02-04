import SwiftUI
import SwiftData
import PhotosUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedMake: VehicleMake?
    @State private var selectedModel: VehicleModel?
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var currentOdometer = ""
    @State private var odometerUnit: OdometerUnit = .miles
    @State private var fuelType: FuelType = .gasoline
    @State private var tankCapacity = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var vehicleImage: Data?
    @State private var notes = ""

    // API data
    @State private var availableMakes: [VehicleMake] = []
    @State private var availableModels: [VehicleModel] = []
    @State private var isLoadingMakes = false
    @State private var isLoadingModels = false
    @State private var apiError: String?

    // Manual entry fallback
    @State private var manualMake = ""
    @State private var manualModel = ""
    @State private var useManualEntry = false

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    private let vehicleDataService = VehicleDataService.shared
    private let currentYear = Calendar.current.component(.year, from: Date())
    private var yearRange: [Int] {
        Array((1990...(currentYear + 1)).reversed())
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let vehicleImage,
                           let uiImage = UIImage(data: vehicleImage) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Add Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Vehicle Information Section
                Section("Vehicle Information") {
                    TextField("Nickname (optional)", text: $name)

                    // Year Picker
                    Picker("Year", selection: $year) {
                        ForEach(yearRange, id: \.self) { yr in
                            Text(String(yr)).tag(yr)
                        }
                    }
                    .onChange(of: year) { _, _ in
                        loadMakes()
                    }

                    // Make Selection
                    if useManualEntry {
                        TextField("Make", text: $manualMake)
                        TextField("Model", text: $manualModel)
                    } else {
                        // Make Picker
                        HStack {
                            Picker("Make", selection: $selectedMake) {
                                Text("Select Make").tag(nil as VehicleMake?)
                                ForEach(availableMakes) { make in
                                    Text(make.makeDisplay).tag(make as VehicleMake?)
                                }
                            }
                            if isLoadingMakes {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .onChange(of: selectedMake) { _, _ in
                            selectedModel = nil
                            loadModels()
                        }

                        // Model Picker
                        HStack {
                            Picker("Model", selection: $selectedModel) {
                                Text("Select Model").tag(nil as VehicleModel?)
                                ForEach(availableModels) { model in
                                    Text(model.modelName).tag(model as VehicleModel?)
                                }
                            }
                            .disabled(selectedMake == nil)
                            if isLoadingModels {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }

                    // Toggle for manual entry
                    Toggle("Enter manually", isOn: $useManualEntry)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let error = apiError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    TextField("VIN (optional)", text: $vin)
                    TextField("License Plate (optional)", text: $licensePlate)
                }

                // Specifications Section
                Section("Specifications") {
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    HStack {
                        TextField("Current Odometer", text: $currentOdometer)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $odometerUnit) {
                            ForEach(OdometerUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }

                    TextField("Tank Capacity (gallons)", text: $tankCapacity)
                        .keyboardType(.decimalPad)
                }

                // Notes Section
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadMakes()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        vehicleImage = data
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        if useManualEntry {
            return !manualMake.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !manualModel.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return selectedMake != nil && selectedModel != nil
        }
    }

    private var makeValue: String {
        if useManualEntry {
            return manualMake.trimmingCharacters(in: .whitespaces)
        }
        return selectedMake?.makeDisplay ?? ""
    }

    private var modelValue: String {
        if useManualEntry {
            return manualModel.trimmingCharacters(in: .whitespaces)
        }
        return selectedModel?.modelName ?? ""
    }

    // MARK: - API Calls

    private func loadMakes() {
        guard !useManualEntry else { return }

        isLoadingMakes = true
        apiError = nil

        Task {
            do {
                let makes = try await vehicleDataService.getMakes(year: year)
                await MainActor.run {
                    availableMakes = makes
                    isLoadingMakes = false

                    // If previously selected make is not available for this year, reset
                    if let selected = selectedMake,
                       !makes.contains(where: { $0.makeId == selected.makeId }) {
                        selectedMake = nil
                        selectedModel = nil
                        availableModels = []
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingMakes = false
                    apiError = "Failed to load makes. You can enter manually."
                    useManualEntry = true
                }
            }
        }
    }

    private func loadModels() {
        guard !useManualEntry,
              let make = selectedMake else {
            availableModels = []
            return
        }

        isLoadingModels = true

        Task {
            do {
                let models = try await vehicleDataService.getModels(make: make.makeId, year: year)
                await MainActor.run {
                    availableModels = models
                    isLoadingModels = false
                }
            } catch {
                await MainActor.run {
                    isLoadingModels = false
                    apiError = "Failed to load models."
                }
            }
        }
    }

    // MARK: - Save

    private func saveVehicle() {
        guard isValid else {
            validationErrorMessage = "Please select or enter the vehicle make and model."
            showingValidationError = true
            return
        }

        let vehicle = Vehicle(
            name: name.trimmingCharacters(in: .whitespaces),
            make: makeValue,
            model: modelValue,
            year: year,
            currentOdometer: Double(currentOdometer) ?? 0,
            odometerUnit: odometerUnit,
            fuelType: fuelType
        )

        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate
        vehicle.tankCapacity = Double(tankCapacity)
        vehicle.imageData = vehicleImage
        vehicle.notes = notes.isEmpty ? nil : notes

        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
