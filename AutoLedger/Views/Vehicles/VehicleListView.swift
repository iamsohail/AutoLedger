import SwiftUI
import SwiftData

struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.createdAt, order: .reverse) private var vehicles: [Vehicle]
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddVehicle = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(vehicles.filter { $0.isActive }) { vehicle in
                    NavigationLink {
                        VehicleDetailView(vehicle: vehicle)
                    } label: {
                        VehicleRowView(vehicle: vehicle, isSelected: vehicle.id == selectedVehicle?.id)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            vehicleToDelete = vehicle
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            selectedVehicle = vehicle
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .tint(.green)
                    }
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .confirmationDialog(
                "Delete Vehicle",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let vehicle = vehicleToDelete {
                        deleteVehicle(vehicle)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this vehicle? All associated data will be permanently removed.")
            }
            .overlay {
                if vehicles.filter({ $0.isActive }).isEmpty {
                    ContentUnavailableView {
                        Label("No Vehicles", systemImage: "car.fill")
                    } description: {
                        Text("Add your first vehicle to start tracking.")
                    } actions: {
                        Button("Add Vehicle") {
                            showingAddVehicle = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    private func deleteVehicle(_ vehicle: Vehicle) {
        vehicle.isActive = false
        if selectedVehicle?.id == vehicle.id {
            selectedVehicle = vehicles.filter { $0.isActive && $0.id != vehicle.id }.first
        }
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VehicleIconView(vehicle: vehicle)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.displayName)
                        .font(.headline)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                Text("\(vehicle.make) \(vehicle.model)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(vehicle.currentOdometer.asMileage(unit: vehicle.odometerUnit))
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let avgMPG = vehicle.averageFuelEconomy {
                    Text("\(String(format: "%.1f", avgMPG)) MPG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VehicleListView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
