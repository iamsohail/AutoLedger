import SwiftUI
import SwiftData

struct TripContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @State private var showingStartTrip = false
    @State private var tripToDelete: Trip?
    @State private var showingDeleteConfirmation = false

    private var trips: [Trip] {
        guard let vehicle = selectedVehicle else { return [] }
        return (vehicle.trips ?? []).sorted { $0.date > $1.date }
    }

    private var activeTrip: Trip? {
        trips.first { $0.isActive }
    }

    var body: some View {
        Group {
            if let vehicle = selectedVehicle {
                List {
                    if let active = activeTrip {
                        Section("Active Trip") {
                            ActiveTripRowView(trip: active, vehicle: vehicle)
                        }
                        .darkListRowStyle()
                    }

                    Section {
                        TripSummaryView(trips: trips)
                    }
                    .darkListRowStyle()

                    Section("Trip History") {
                        if trips.filter({ !$0.isActive }).isEmpty {
                            Text("No Completed Trips Yet")
                                .foregroundColor(.textSecondary)
                        } else {
                            ForEach(trips.filter { !$0.isActive }) { trip in
                                TripRowView(trip: trip, vehicle: vehicle)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            tripToDelete = trip
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
                    description: Text("Select a vehicle to view trips")
                )
            }
        }
        .sheet(isPresented: $showingStartTrip) {
            if let vehicle = selectedVehicle {
                StartTripView(vehicle: vehicle)
            }
        }
        .confirmationDialog(
            "Delete Trip",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    modelContext.delete(trip)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this trip?")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStartTrip = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedVehicle == nil || activeTrip != nil)
            }
        }
    }
}

// MARK: - Trip Summary

struct TripSummaryView: View {
    let trips: [Trip]

    private var totalDistance: Double {
        trips.reduce(0) { $0 + $1.calculatedDistance }
    }

    private var businessDistance: Double {
        trips.filter { $0.tripType == .business }.reduce(0) { $0 + $1.calculatedDistance }
    }

    private var totalReimbursement: Double {
        trips.compactMap { $0.reimbursementAmount }.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                SummaryStatView(
                    title: "Total Miles",
                    value: String(format: "%.0f", totalDistance),
                    color: .tripColor
                )

                SummaryStatView(
                    title: "Business Miles",
                    value: String(format: "%.0f", businessDistance),
                    color: .blue
                )

                if totalReimbursement > 0 {
                    SummaryStatView(
                        title: "Reimbursement",
                        value: totalReimbursement.asCurrency,
                        color: .green
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Active Trip Row

struct ActiveTripRowView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    let vehicle: Vehicle
    @State private var showingEndTrip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: trip.tripType.icon)
                    .foregroundColor(.tripColor)
                Text(trip.tripType.rawValue)
                    .font(Theme.Typography.headline)
                Spacer()
                Text("In Progress")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            }

            Text("Started: \(trip.date.formatted(style: .medium))")
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)

            Button("End Trip") {
                showingEndTrip = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEndTrip) {
            EndTripView(trip: trip, vehicle: vehicle)
        }
    }
}

// MARK: - Trip Row

struct TripRowView: View {
    let trip: Trip
    let vehicle: Vehicle

    var body: some View {
        HStack {
            Image(systemName: trip.tripType.icon)
                .font(Theme.Typography.title2)
                .foregroundColor(.tripColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trip.tripType.rawValue)
                        .font(Theme.Typography.headline)
                    if trip.tripType.isTaxDeductible {
                        Image(systemName: "checkmark.seal.fill")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.green)
                    }
                }
                Text(trip.date.formatted(style: .medium))
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", trip.calculatedDistance)) mi")
                    .font(Theme.Typography.headline)
                if let reimbursement = trip.reimbursementAmount {
                    Text(reimbursement.asCurrency)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
