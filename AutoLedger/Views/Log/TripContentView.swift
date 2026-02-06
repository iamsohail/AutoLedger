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
                    }

                    Section {
                        TripSummaryView(trips: trips)
                    }

                    Section("Trip History") {
                        if trips.filter({ !$0.isActive }).isEmpty {
                            Text("No Completed Trips Yet")
                                .foregroundColor(.secondary)
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
