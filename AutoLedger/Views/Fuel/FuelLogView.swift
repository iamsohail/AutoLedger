import SwiftUI
import SwiftData

struct FuelLogView: View {
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
        NavigationStack {
            List {
                if let vehicle = selectedVehicle {
                    Section {
                        FuelSummaryView(vehicle: vehicle)
                    }

                    Section("Fill-ups") {
                        if fuelEntries.isEmpty {
                            Text("No fuel entries yet")
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
            }
            .navigationTitle("Fuel Log")
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
            .overlay {
                if selectedVehicle == nil {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Select a vehicle to view fuel logs")
                    )
                }
            }
        }
    }
}

struct FuelSummaryView: View {
    let vehicle: Vehicle

    private var totalGallons: Double {
        (vehicle.fuelEntries ?? []).reduce(0) { $0 + $1.quantity }
    }

    private var averagePricePerGallon: Double {
        let entries = vehicle.fuelEntries ?? []
        guard !entries.isEmpty else { return 0 }
        return entries.reduce(0) { $0 + $1.pricePerUnit } / Double(entries.count)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                SummaryStatView(
                    title: "Total Cost",
                    value: vehicle.totalFuelCost.asCurrency,
                    color: .fuelColor
                )

                SummaryStatView(
                    title: "Total Gallons",
                    value: String(format: "%.1f", totalGallons),
                    color: .fuelColor
                )

                if let avgMPG = vehicle.averageFuelEconomy {
                    SummaryStatView(
                        title: "Avg MPG",
                        value: String(format: "%.1f", avgMPG),
                        color: .green
                    )
                }
            }

            if averagePricePerGallon > 0 {
                Text("Avg price: \(averagePricePerGallon.asCurrency)/gal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SummaryStatView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FuelEntryRowView: View {
    let entry: FuelEntry
    let vehicle: Vehicle

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.formatted(style: .medium))
                    .font(.headline)
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", entry.quantity)) gal")
                    Text("@")
                        .foregroundColor(.secondary)
                    Text("\(entry.pricePerUnit.asCurrency)/gal")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.totalCost.asCurrency)
                    .font(.headline)
                if let mpg = entry.fuelEconomy {
                    Text("\(String(format: "%.1f", mpg)) MPG")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FuelLogView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
