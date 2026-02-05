import SwiftUI
import SwiftData
import PhotosUI

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vehicle: Vehicle

    @State private var name: String = ""
    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2024
    @State private var vin: String = ""
    @State private var licensePlate: String = ""
    @State private var currentOdometer: String = ""
    @State private var odometerUnit: OdometerUnit = .miles
    @State private var fuelType: FuelType = .petrol
    @State private var tankCapacity: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var vehicleImage: Data?
    @State private var notes: String = ""

    // Insurance
    @State private var insuranceProvider: String = ""
    @State private var insurancePolicyNumber: String = ""
    @State private var insuranceExpirationDate: Date = Date()
    @State private var hasInsuranceExpiration: Bool = false

    // Registration
    @State private var registrationState: String = ""
    @State private var registrationExpirationDate: Date = Date()
    @State private var hasRegistrationExpiration: Bool = false

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

                Section("Insurance") {
                    TextField("Provider", text: $insuranceProvider)
                    TextField("Policy Number", text: $insurancePolicyNumber)
                    Toggle("Has Expiration Date", isOn: $hasInsuranceExpiration)
                    if hasInsuranceExpiration {
                        DatePicker("Expiration", selection: $insuranceExpirationDate, displayedComponents: .date)
                    }
                }

                Section("Registration") {
                    TextField("State", text: $registrationState)
                    Toggle("Has Expiration Date", isOn: $hasRegistrationExpiration)
                    if hasRegistrationExpiration {
                        DatePicker("Expiration", selection: $registrationExpirationDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadVehicleData()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        vehicleImage = data
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadVehicleData() {
        name = vehicle.name
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        vin = vehicle.vin ?? ""
        licensePlate = vehicle.licensePlate ?? ""
        currentOdometer = String(format: "%.0f", vehicle.currentOdometer)
        odometerUnit = vehicle.odometerUnit
        fuelType = vehicle.fuelType
        tankCapacity = vehicle.tankCapacity != nil ? String(format: "%.1f", vehicle.tankCapacity!) : ""
        vehicleImage = vehicle.imageData
        notes = vehicle.notes ?? ""

        insuranceProvider = vehicle.insuranceProvider ?? ""
        insurancePolicyNumber = vehicle.insurancePolicyNumber ?? ""
        if let expiration = vehicle.insuranceExpirationDate {
            insuranceExpirationDate = expiration
            hasInsuranceExpiration = true
        }

        registrationState = vehicle.registrationState ?? ""
        if let expiration = vehicle.registrationExpirationDate {
            registrationExpirationDate = expiration
            hasRegistrationExpiration = true
        }
    }

    private func saveChanges() {
        vehicle.name = name.trimmingCharacters(in: .whitespaces)
        vehicle.make = make.trimmingCharacters(in: .whitespaces)
        vehicle.model = model.trimmingCharacters(in: .whitespaces)
        vehicle.year = year
        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.licensePlate = licensePlate.isEmpty ? nil : licensePlate
        vehicle.currentOdometer = Double(currentOdometer) ?? vehicle.currentOdometer
        vehicle.odometerUnit = odometerUnit
        vehicle.fuelType = fuelType
        vehicle.tankCapacity = Double(tankCapacity)
        vehicle.imageData = vehicleImage
        vehicle.notes = notes.isEmpty ? nil : notes

        vehicle.insuranceProvider = insuranceProvider.isEmpty ? nil : insuranceProvider
        vehicle.insurancePolicyNumber = insurancePolicyNumber.isEmpty ? nil : insurancePolicyNumber
        vehicle.insuranceExpirationDate = hasInsuranceExpiration ? insuranceExpirationDate : nil

        vehicle.registrationState = registrationState.isEmpty ? nil : registrationState
        vehicle.registrationExpirationDate = hasRegistrationExpiration ? registrationExpirationDate : nil

        vehicle.updatedAt = Date()

        dismiss()
    }
}

#Preview {
    EditVehicleView(vehicle: Vehicle(
        name: "My Car",
        make: "Toyota",
        model: "Camry",
        year: 2022
    ))
    .modelContainer(for: Vehicle.self, inMemory: true)
}
