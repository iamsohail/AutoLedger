import SwiftUI
import SwiftData

struct StartTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var date = Date()
    @State private var startOdometer = ""
    @State private var tripType: TripType = .personal
    @State private var purpose = ""
    @State private var startLocation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    DatePicker("Start Time", selection: $date)

                    HStack {
                        TextField("Start Odometer", text: $startOdometer)
                            .keyboardType(.decimalPad)
                        Text(vehicle.odometerUnit.abbreviation)
                            .foregroundColor(.secondary)
                    }

                    Picker("Trip Type", selection: $tripType) {
                        ForEach(TripType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    if tripType.isTaxDeductible {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Tax Deductible")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                Section("Purpose (Optional)") {
                    TextField("Trip purpose or description", text: $purpose)
                }

                Section("Start Location (Optional)") {
                    TextField("Starting location", text: $startLocation)
                }

                if tripType == .business {
                    Section {
                        Text("IRS Rate: \(String(format: "$%.2f", Trip.businessMileageRate))/mile")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Start Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        startTrip()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                startOdometer = String(format: "%.0f", vehicle.currentOdometer)
            }
        }
    }

    private var isValid: Bool {
        guard let odo = Double(startOdometer), odo > 0 else { return false }
        return true
    }

    private func startTrip() {
        guard let odo = Double(startOdometer) else { return }

        let trip = Trip(
            date: date,
            startOdometer: odo,
            tripType: tripType,
            purpose: purpose.isEmpty ? nil : purpose,
            startLocation: startLocation.isEmpty ? nil : startLocation
        )

        trip.vehicle = vehicle
        modelContext.insert(trip)
        dismiss()
    }
}

#Preview {
    StartTripView(vehicle: Vehicle(
        name: "Test",
        make: "Toyota",
        model: "Camry",
        year: 2022
    ))
    .modelContainer(for: Vehicle.self, inMemory: true)
}
