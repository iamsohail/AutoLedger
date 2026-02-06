import SwiftUI
import SwiftData

struct MaintenanceContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddRecord = false
    @State private var recordToDelete: MaintenanceRecord?
    @State private var showingDeleteConfirmation = false

    private var maintenanceRecords: [MaintenanceRecord] {
        guard let vehicle = selectedVehicle else { return [] }
        return (vehicle.maintenanceRecords ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if let vehicle = selectedVehicle {
                List {
                    Section {
                        MaintenanceSummaryView(vehicle: vehicle)
                    }

                    Section("Service History") {
                        if maintenanceRecords.isEmpty {
                            Text("No Maintenance Records Yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(maintenanceRecords) { record in
                                MaintenanceRecordRowView(record: record)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            recordToDelete = record
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.darkBackground)
            } else {
                ContentUnavailableView(
                    "No Vehicle Selected",
                    systemImage: "car.fill",
                    description: Text("Select a vehicle to view maintenance history")
                )
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            if let vehicle = selectedVehicle {
                AddMaintenanceRecordView(vehicle: vehicle)
            }
        }
        .confirmationDialog(
            "Delete Record",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    modelContext.delete(record)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this maintenance record?")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedVehicle == nil)
            }
        }
    }
}
