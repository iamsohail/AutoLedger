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
    @State private var showingScanner = false
    @State private var isScanning = false
    @State private var scanFeedback: String?

    var body: some View {
        NavigationStack {
            Form {
                // Scan Receipt Section
                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title2)
                                .foregroundColor(.primaryPurple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan Fuel Receipt")
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(.textPrimary)
                                Text("Auto-fill from a photo of your bill")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            if isScanning {
                                ProgressView()
                                    .tint(.primaryPurple)
                            } else {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                    }
                    .disabled(isScanning)

                    if let feedback = scanFeedback {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.greenAccent)
                            Text(feedback)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.greenAccent)
                        }
                    }
                }

                Section("Fill-Up Details") {
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
            .fullScreenCover(isPresented: $showingScanner) {
                DocumentScannerView(
                    onScan: { image in
                        showingScanner = false
                        processScannedImage(image)
                    },
                    onCancel: {
                        showingScanner = false
                    }
                )
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Scanner Processing

    private func processScannedImage(_ image: UIImage) {
        isScanning = true
        scanFeedback = nil

        Task {
            let result = await ReceiptScannerService.scanReceipt(image: image)
            await MainActor.run {
                applyScannedData(result)
                isScanning = false
            }
        }
    }

    private func applyScannedData(_ data: ScannedFuelData) {
        var fieldsFound = 0

        if let scannedDate = data.date {
            date = scannedDate
            fieldsFound += 1
        }

        if let qty = data.quantity {
            quantity = String(format: "%.2f", qty)
            fieldsFound += 1
        }

        if let rate = data.pricePerUnit {
            pricePerUnit = String(format: "%.2f", rate)
            fieldsFound += 1
        }

        if let stationName = data.stationName, station.isEmpty {
            station = stationName
            fieldsFound += 1
        }

        if let fuelTypeStr = data.fuelType {
            // Map scanned fuel type to FuelGrade
            let upper = fuelTypeStr.uppercased()
            if upper.contains("PREMIUM") {
                fuelGrade = .premium
            } else if upper.contains("DIESEL") {
                fuelGrade = .diesel
            } else {
                fuelGrade = .regular
            }
            fieldsFound += 1
        }

        if fieldsFound > 0 {
            let method = data.scanMethod == .ai ? "AI" : "OCR"
            scanFeedback = "\(fieldsFound) field\(fieldsFound == 1 ? "" : "s") auto-filled (\(method))"
        } else {
            scanFeedback = nil
            validationErrorMessage = "Could not extract data from the receipt. Please enter details manually."
            showingValidationError = true
        }
    }

    // MARK: - Validation & Save

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
            validationErrorMessage = "Please Enter Valid Numbers for Odometer, Quantity, and Price."
            showingValidationError = true
            return
        }

        if odo < vehicle.currentOdometer {
            validationErrorMessage = "Odometer Reading Cannot Be Less Than the Current Odometer (\(vehicle.currentOdometer.asMileage(unit: vehicle.odometerUnit)))."
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
