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
                    .darkListRowStyle()

                    Section("Service History") {
                        if maintenanceRecords.isEmpty {
                            Text("No Maintenance Records Yet")
                                .foregroundColor(.textSecondary)
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
                    .darkListRowStyle()
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

// MARK: - Maintenance Summary

struct MaintenanceSummaryView: View {
    let vehicle: Vehicle

    private var recordCount: Int {
        vehicle.maintenanceRecords?.count ?? 0
    }

    var body: some View {
        HStack(spacing: 24) {
            SummaryStatView(
                title: "Total Spent",
                value: vehicle.totalMaintenanceCost.asCurrency,
                color: .maintenanceColor
            )

            SummaryStatView(
                title: "Services",
                value: "\(recordCount)",
                color: .maintenanceColor
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Maintenance Record Row

struct MaintenanceRecordRowView: View {
    let record: MaintenanceRecord

    var body: some View {
        HStack {
            Image(systemName: record.serviceType.icon)
                .font(Theme.Typography.title2)
                .foregroundColor(.maintenanceColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.displayName)
                    .font(Theme.Typography.headline)
                HStack {
                    Text(record.date.formatted(style: .medium))
                    if record.odometer > 0 {
                        Text("\u{2022}")
                        Text("\(String(format: "%.0f", record.odometer)) mi")
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(record.cost.asCurrency)
                .font(Theme.Typography.headline)
        }
        .padding(.vertical, 4)
    }
}
