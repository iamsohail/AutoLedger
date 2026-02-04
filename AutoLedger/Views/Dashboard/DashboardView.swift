import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @Query private var vehicles: [Vehicle]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let vehicle = selectedVehicle {
                    VStack(spacing: 16) {
                        vehiclePicker

                        VehicleSummaryCard(vehicle: vehicle)

                        QuickActionsView(vehicle: vehicle)

                        if let entries = vehicle.fuelEntries, !entries.isEmpty {
                            FuelEconomyChartView(entries: entries)
                        }

                        UpcomingMaintenanceView(vehicle: vehicle)

                        RecentActivityView(vehicle: vehicle)
                    }
                    .padding()
                } else {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Select a vehicle to view its dashboard")
                    )
                }
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var vehiclePicker: some View {
        Menu {
            ForEach(vehicles.filter { $0.isActive }) { vehicle in
                Button {
                    selectedVehicle = vehicle
                } label: {
                    HStack {
                        Text(vehicle.displayName)
                        if vehicle.id == selectedVehicle?.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let vehicle = selectedVehicle {
                    VehicleIconView(vehicle: vehicle)
                    Text(vehicle.displayName)
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
    }
}

struct VehicleSummaryCard: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(vehicle.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(vehicle.year)")
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack(spacing: 24) {
                StatView(
                    title: "Odometer",
                    value: vehicle.currentOdometer.asMileage(unit: vehicle.odometerUnit),
                    icon: "speedometer"
                )

                if let avgMPG = vehicle.averageFuelEconomy {
                    StatView(
                        title: "Avg MPG",
                        value: String(format: "%.1f", avgMPG),
                        icon: "fuelpump.fill"
                    )
                }

                StatView(
                    title: "Total Spent",
                    value: (vehicle.totalFuelCost + vehicle.totalMaintenanceCost).asCurrency,
                    icon: "dollarsign.circle.fill"
                )
            }
        }
        .cardStyle()
    }
}

struct StatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct VehicleIconView: View {
    let vehicle: Vehicle

    var body: some View {
        Image(systemName: vehicleIcon)
            .font(.title3)
            .foregroundColor(.accentColor)
    }

    private var vehicleIcon: String {
        switch vehicle.fuelType {
        case .electric:
            return "bolt.car.fill"
        case .hybrid, .plugInHybrid:
            return "leaf.fill"
        default:
            return "car.fill"
        }
    }
}

struct QuickActionsView: View {
    let vehicle: Vehicle
    @State private var showingAddFuel = false
    @State private var showingAddMaintenance = false
    @State private var showingStartTrip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Fuel",
                    icon: "fuelpump.fill",
                    color: .fuelColor
                ) {
                    showingAddFuel = true
                }

                QuickActionButton(
                    title: "Log Service",
                    icon: "wrench.fill",
                    color: .maintenanceColor
                ) {
                    showingAddMaintenance = true
                }

                QuickActionButton(
                    title: "Start Trip",
                    icon: "location.fill",
                    color: .tripColor
                ) {
                    showingStartTrip = true
                }
            }
        }
        .sheet(isPresented: $showingAddFuel) {
            AddFuelEntryView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingAddMaintenance) {
            AddMaintenanceRecordView(vehicle: vehicle)
        }
        .sheet(isPresented: $showingStartTrip) {
            StartTripView(vehicle: vehicle)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct FuelEconomyChartView: View {
    let entries: [FuelEntry]

    private var chartData: [(date: Date, mpg: Double)] {
        entries
            .sorted { $0.date < $1.date }
            .suffix(10)
            .compactMap { entry in
                guard let mpg = entry.fuelEconomy else { return nil }
                return (entry.date, mpg)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fuel Economy Trend")
                .font(.headline)

            if chartData.isEmpty {
                Text("Not enough data to display chart")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("MPG", item.mpg)
                    )
                    .foregroundStyle(Color.fuelColor)

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("MPG", item.mpg)
                    )
                    .foregroundStyle(Color.fuelColor)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .cardStyle()
    }
}

struct UpcomingMaintenanceView: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Maintenance")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    MaintenanceListView(selectedVehicle: .constant(vehicle))
                }
                .font(.subheadline)
            }

            // Placeholder for upcoming maintenance items
            Text("No upcoming maintenance scheduled")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .cardStyle()
    }
}

struct RecentActivityView: View {
    let vehicle: Vehicle

    private var recentFuelEntries: [FuelEntry] {
        (vehicle.fuelEntries ?? [])
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if recentFuelEntries.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentFuelEntries) { entry in
                    HStack {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.fuelColor)
                        VStack(alignment: .leading) {
                            Text("Fuel Fill-up")
                                .font(.subheadline)
                            Text(entry.date.formatted(style: .medium))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(entry.totalCost.asCurrency)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    DashboardView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
