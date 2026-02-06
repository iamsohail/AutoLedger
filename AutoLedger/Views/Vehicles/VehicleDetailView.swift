import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var vehicle: Vehicle
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section {
                VehicleHeaderView(vehicle: vehicle)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Details") {
                DetailRow(label: "Make", value: vehicle.make)
                DetailRow(label: "Model", value: vehicle.model)
                DetailRow(label: "Year", value: String(vehicle.year))
                if let vin = vehicle.vin, !vin.isEmpty {
                    DetailRow(label: "VIN", value: vin)
                }
                if let plate = vehicle.licensePlate, !plate.isEmpty {
                    DetailRow(label: "License Plate", value: plate)
                }
                DetailRow(label: "Fuel Type", value: vehicle.fuelType.rawValue)
                DetailRow(label: "Odometer", value: vehicle.currentOdometer.asMileage(unit: vehicle.odometerUnit))
            }

            if vehicle.insuranceProvider != nil || vehicle.insuranceExpirationDate != nil {
                Section("Insurance") {
                    if let provider = vehicle.insuranceProvider {
                        DetailRow(label: "Provider", value: provider)
                    }
                    if let policyNumber = vehicle.insurancePolicyNumber {
                        DetailRow(label: "Policy #", value: policyNumber)
                    }
                    if let expiration = vehicle.insuranceExpirationDate {
                        DetailRow(label: "Expires", value: expiration.formatted(style: .medium))
                    }
                }
            }

            if vehicle.registrationState != nil || vehicle.registrationExpirationDate != nil {
                Section("Registration") {
                    if let state = vehicle.registrationState {
                        DetailRow(label: "State", value: state)
                    }
                    if let expiration = vehicle.registrationExpirationDate {
                        DetailRow(label: "Expires", value: expiration.formatted(style: .medium))
                    }
                }
            }

            Section("Statistics") {
                DetailRow(label: "Total Fuel Cost", value: vehicle.totalFuelCost.asCurrency)
                DetailRow(label: "Total Maintenance Cost", value: vehicle.totalMaintenanceCost.asCurrency)
                DetailRow(label: "Total Cost", value: (vehicle.totalFuelCost + vehicle.totalMaintenanceCost).asCurrency)
                if let avgMPG = vehicle.averageFuelEconomy {
                    DetailRow(label: "Average Fuel Economy", value: String(format: "%.1f km/l", avgMPG))
                }
                DetailRow(label: "Fuel Entries", value: "\(vehicle.fuelEntries?.count ?? 0)")
                DetailRow(label: "Maintenance Records", value: "\(vehicle.maintenanceRecords?.count ?? 0)")
                DetailRow(label: "Trips", value: "\(vehicle.trips?.count ?? 0)")
            }

            if let notes = vehicle.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(Theme.Typography.body)
                }
            }
        }
        .navigationTitle(vehicle.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditVehicleView(vehicle: vehicle)
        }
    }
}

struct VehicleHeaderView: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(spacing: 16) {
            if let imageData = vehicle.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(height: 120)

                    VStack(spacing: 12) {
                        BrandLogoView(
                            make: vehicle.make,
                            size: 60,
                            type: .icon,
                            fallbackIcon: "car.fill",
                            fallbackColor: .accentColor
                        )

                        Text(vehicle.displayName)
                            .font(Theme.Typography.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: Vehicle(
            name: "My Car",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            currentOdometer: 25000
        ))
    }
    .modelContainer(for: Vehicle.self, inMemory: true)
}
