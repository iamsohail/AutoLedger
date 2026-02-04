import SwiftUI
import SwiftData
import PhotosUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedMake: IndianVehicleMake?
    @State private var selectedModel: String?
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var currentOdometer = ""
    @State private var odometerUnit: OdometerUnit = .kilometers
    @State private var fuelType: FuelType = .gasoline
    @State private var tankCapacity = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var vehicleImage: Data?
    @State private var notes = ""

    // Manual entry fallback
    @State private var manualMake = ""
    @State private var manualModel = ""
    @State private var useManualEntry = false

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    private let vehicleDataService = VehicleDataService.shared
    private let currentYear = Calendar.current.component(.year, from: Date())

    private var yearRange: [Int] {
        Array((2000...(currentYear + 1)).reversed())
    }

    private var availableMakes: [IndianVehicleMake] {
        vehicleDataService.getMakes()
    }

    private var availableModels: [String] {
        guard let make = selectedMake else { return [] }
        return make.models
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

                    // Make & Model Selection
                    if useManualEntry {
                        TextField("Make", text: $manualMake)
                        TextField("Model", text: $manualModel)
                    } else {
                        // Make Picker
                        Picker("Make", selection: $selectedMake) {
                            Text("Select Make").tag(nil as IndianVehicleMake?)
                            ForEach(availableMakes) { make in
                                Text(make.name).tag(make as IndianVehicleMake?)
                            }
                        }
                        .onChange(of: selectedMake) { _, _ in
                            selectedModel = nil
                        }

                        // Model Picker
                        Picker("Model", selection: $selectedModel) {
                            Text("Select Model").tag(nil as String?)
                            ForEach(availableModels, id: \.self) { model in
                                Text(model).tag(model as String?)
                            }
                        }
                        .disabled(selectedMake == nil)
                    }

                    // Toggle for manual entry
                    Toggle("Enter manually", isOn: $useManualEntry)
                        .font(.caption)
                        .foregroundColor(.secondary)

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

                    TextField("Tank Capacity (liters)", text: $tankCapacity)
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
        return selectedMake?.name ?? ""
    }

    private var modelValue: String {
        if useManualEntry {
            return manualModel.trimmingCharacters(in: .whitespaces)
        }
        return selectedModel ?? ""
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
