import SwiftUI
import SwiftData

struct FuelLogContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddEntry = false
    @State private var entryToDelete: FuelEntry?
    @State private var showingDeleteConfirmation = false

    private var fuelEntries: [FuelEntry] {
        guard let vehicle = selectedVehicle else { return [] }
        return (vehicle.fuelEntries ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if let vehicle = selectedVehicle {
                List {
                    Section {
                        FuelSummaryView(vehicle: vehicle)
                    }

                    Section("Fill-Ups") {
                        if fuelEntries.isEmpty {
                            Text("No Fuel Entries Yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(fuelEntries) { entry in
                                FuelEntryRowView(entry: entry, vehicle: vehicle)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
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
                    description: Text("Select a vehicle to view fuel logs")
                )
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            if let vehicle = selectedVehicle {
                AddFuelEntryView(vehicle: vehicle)
            }
        }
        .confirmationDialog(
            "Delete Entry",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    modelContext.delete(entry)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this fuel entry?")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddEntry = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedVehicle == nil)
            }
        }
    }
}
