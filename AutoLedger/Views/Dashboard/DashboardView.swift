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
                    VStack(spacing: Theme.Spacing.md) {
                        GreetingHeaderView()

                        vehiclePicker

                        VehicleHeroCard(vehicle: vehicle)

                        // Gauge row
                        HStack(spacing: Theme.Spacing.md) {
                            SpeedometerGaugeView(
                                value: vehicle.currentOdometer,
                                maxValue: max(vehicle.currentOdometer * 1.5, 100000),
                                title: "Odometer",
                                unit: vehicle.odometerUnit.abbreviation,
                                color: .primaryPurple
                            )
                            .frame(maxWidth: .infinity)
                            .darkCardStyle()

                            if let avgMPG = vehicle.averageFuelEconomy {
                                CircularGaugeView(
                                    value: avgMPG,
                                    maxValue: 50,
                                    title: "Avg Fuel Economy",
                                    unit: "km/l",
                                    color: .greenAccent,
                                    size: 100
                                )
                                .frame(maxWidth: .infinity)
                                .darkCardStyle()
                            }
                        }

                        QuickActionsView(vehicle: vehicle)

                        if let entries = vehicle.fuelEntries, !entries.isEmpty {
                            FuelEconomyChartView(entries: entries)
                        }

                        RecentActivityView(vehicle: vehicle)
                    }
                    .padding(Theme.Spacing.md)
                } else {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Select a Vehicle to View Its Dashboard")
                    )
                }
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
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
                        .font(Theme.Typography.headline)
                        .foregroundColor(.textPrimary)
                }
                Image(systemName: "chevron.down")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(Theme.CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.pill)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct VehicleIconView: View {
    let vehicle: Vehicle

    var body: some View {
        BrandLogoView(
            make: vehicle.make,
            size: 28,
            type: .icon,
            fallbackIcon: vehicleIcon,
            fallbackColor: .primaryPurple
        )
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick Actions")
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                QuickActionButton(
                    title: "Add Fuel",
                    icon: "fuelpump.fill",
                    color: .greenAccent
                ) {
                    showingAddFuel = true
                }

                QuickActionButton(
                    title: "Log Service",
                    icon: "wrench.fill",
                    color: .primaryPurple
                ) {
                    showingAddMaintenance = true
                }

                QuickActionButton(
                    title: "Start Trip",
                    icon: "location.fill",
                    color: .pinkAccent
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
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(Theme.Typography.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textPrimary)
            }
            .quickActionStyle(color: color)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Fuel Economy Trend")
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)

            if chartData.isEmpty {
                Text("Not Enough Data to Display Chart")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Chart(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("km/l", item.mpg)
                    )
                    .foregroundStyle(Color.greenAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("km/l", item.mpg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.greenAccent.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("km/l", item.mpg)
                    )
                    .foregroundStyle(Color.greenAccent)
                    .symbolSize(40)
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
        .darkCardStyle()
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recent Activity")
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)

            if recentFuelEntries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "clock")
                            .font(Theme.Typography.largeTitle)
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text("No Recent Activity")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, Theme.Spacing.lg)
                    Spacer()
                }
            } else {
                ForEach(recentFuelEntries) { entry in
                    HStack(spacing: Theme.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(Color.greenAccent.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "fuelpump.fill")
                                .foregroundColor(.greenAccent)
                                .font(Theme.Typography.cardSubtitle)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fuel Fill-Up")
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.textPrimary)
                            Text(entry.date.formatted(style: .medium))
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Text(entry.totalCost.asCurrency)
                            .font(Theme.Typography.cardSubtitle)
                            .foregroundColor(.greenAccent)
                    }
                    .padding(.vertical, Theme.Spacing.xs)

                    if entry.id != recentFuelEntries.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
        }
        .darkCardStyle()
    }
}

#Preview {
    DashboardView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
