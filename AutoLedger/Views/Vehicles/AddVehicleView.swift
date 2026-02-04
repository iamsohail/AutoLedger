import SwiftUI
import SwiftData
import PhotosUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
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

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    private let currentYear = Calendar.current.component(.year, from: Date())
    private var yearRange: ClosedRange<Int> { 1900...(currentYear + 1) }

    var body: some View {
        NavigationStack {
            Form {
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

                Section("Vehicle Information") {
                    TextField("Nickname (optional)", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    Picker("Year", selection: $year) {
                        ForEach(yearRange.reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    TextField("VIN (optional)", text: $vin)
                    TextField("License Plate (optional)", text: $licensePlate)
                }

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
                    TextField("Tank Capacity (optional)", text: $tankCapacity)
                        .keyboardType(.decimalPad)
                }

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

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveVehicle() {
        guard isValid else {
            validationErrorMessage = "Please enter the vehicle make and model."
            showingValidationError = true
            return
        }

        let vehicle = Vehicle(
            name: name.trimmingCharacters(in: .whitespaces),
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
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
