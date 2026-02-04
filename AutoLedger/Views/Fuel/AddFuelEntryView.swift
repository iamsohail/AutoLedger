import SwiftUI
import SwiftData

struct AddFuelEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var date = Date()
    @State private var odometer = ""
    @State private var quantity = ""
    @State private var pricePerUnit = ""
    @State private var isFullTank = true
    @State private var fuelGrade: FuelGrade = .regular
    @State private var station = ""
    @State private var location = ""
    @State private var notes = ""

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Fill-up Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    HStack {
                        TextField("Odometer", text: $odometer)
                            .keyboardType(.decimalPad)
                        Text(vehicle.odometerUnit.abbreviation)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.decimalPad)
                        Text("gallons")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Price per gallon", text: $pricePerUnit)
                            .keyboardType(.decimalPad)
                        Text("/gal")
                            .foregroundColor(.secondary)
                    }

                    if let total = calculatedTotal {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(total.asCurrency)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Full Tank", isOn: $isFullTank)

                    Picker("Fuel Grade", selection: $fuelGrade) {
                        ForEach(FuelGrade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                }

                Section("Location (Optional)") {
                    TextField("Station Name", text: $station)
                    TextField("Location", text: $location)
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Add Fuel Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                odometer = String(format: "%.0f", vehicle.currentOdometer)
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    private var calculatedTotal: Double? {
        guard let qty = Double(quantity),
              let price = Double(pricePerUnit) else { return nil }
        return qty * price
    }

    private var isValid: Bool {
        guard let odo = Double(odometer), odo > 0 else { return false }
        guard let qty = Double(quantity), qty > 0 else { return false }
        guard let price = Double(pricePerUnit), price > 0 else { return false }
        return true
    }

    private func saveEntry() {
        guard let odo = Double(odometer),
              let qty = Double(quantity),
              let price = Double(pricePerUnit) else {
            validationErrorMessage = "Please enter valid numbers for odometer, quantity, and price."
            showingValidationError = true
            return
        }

        if odo < vehicle.currentOdometer {
            validationErrorMessage = "Odometer reading cannot be less than the current odometer (\(vehicle.currentOdometer.asMileage(unit: vehicle.odometerUnit)))."
            showingValidationError = true
            return
        }

        let entry = FuelEntry(
            date: date,
            odometer: odo,
            quantity: qty,
            pricePerUnit: price,
            isFullTank: isFullTank,
            fuelGrade: fuelGrade,
            station: station.isEmpty ? nil : station,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes
        )

        entry.vehicle = vehicle
        vehicle.currentOdometer = odo
        vehicle.updatedAt = Date()

        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    AddFuelEntryView(vehicle: Vehicle(
        name: "Test",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentOdometer: 25000
    ))
    .modelContainer(for: Vehicle.self, inMemory: true)
}
