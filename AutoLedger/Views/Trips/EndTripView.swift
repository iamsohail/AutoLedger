import SwiftUI
import SwiftData

struct EndTripView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var trip: Trip
    let vehicle: Vehicle

    @State private var endOdometer = ""
    @State private var endLocation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Summary") {
                    DetailRow(label: "Started", value: trip.date.formatted(style: .medium))
                    DetailRow(label: "Type", value: trip.tripType.rawValue)
                    DetailRow(label: "Start Odometer", value: "\(String(format: "%.0f", trip.startOdometer)) \(vehicle.odometerUnit.abbreviation)")
                }

                Section("End Trip") {
                    HStack {
                        TextField("End Odometer", text: $endOdometer)
                            .keyboardType(.decimalPad)
                        Text(vehicle.odometerUnit.abbreviation)
                            .foregroundColor(.secondary)
                    }

                    TextField("End Location (Optional)", text: $endLocation)
                }

                if let distance = calculatedDistance {
                    Section("Summary") {
                        DetailRow(label: "Distance", value: "\(String(format: "%.1f", distance)) \(vehicle.odometerUnit.abbreviation)")

                        if trip.tripType == .business {
                            DetailRow(
                                label: "Reimbursement",
                                value: (distance * Trip.businessMileageRate).asCurrency
                            )
                        }
                    }
                }
            }
            .navigationTitle("End Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        completeTrip()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                endOdometer = String(format: "%.0f", vehicle.currentOdometer)
            }
        }
    }

    private var calculatedDistance: Double? {
        guard let end = Double(endOdometer) else { return nil }
        let distance = end - trip.startOdometer
        return distance > 0 ? distance : nil
    }

    private var isValid: Bool {
        guard let end = Double(endOdometer) else { return false }
        return end > trip.startOdometer
    }

    private func completeTrip() {
        guard let end = Double(endOdometer) else { return }

        trip.endTrip(
            endOdometer: end,
            endLocation: endLocation.isEmpty ? nil : endLocation
        )

        if end > vehicle.currentOdometer {
            vehicle.currentOdometer = end
            vehicle.updatedAt = Date()
        }

        dismiss()
    }
}

#Preview {
    EndTripView(
        trip: Trip(date: Date(), startOdometer: 25000, tripType: .business),
        vehicle: Vehicle(name: "Test", make: "Toyota", model: "Camry", year: 2022, currentOdometer: 25100)
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}
