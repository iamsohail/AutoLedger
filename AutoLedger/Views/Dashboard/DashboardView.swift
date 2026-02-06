import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @Binding var selectedVehicle: Vehicle?
    @Query private var vehicles: [Vehicle]

    private var displayName: String {
        let name = authService.userProfile?.name ?? ""
        return name.isEmpty ? "Driver" : name
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let vehicle = selectedVehicle {
                    VStack(spacing: 20) {
                        // Hero card (greeting + metric + car image)
                        heroCard(vehicle)

                        // Vehicle picker
                        vehiclePicker

                        // Vehicle info strip
                        vehicleInfoStrip(vehicle)

                        // Stats card with gradient sub-cards
                        statsCard(vehicle)

                        // Quick Actions
                        QuickActionsView(vehicle: vehicle)

                        // Alerts
                        alertsSection(vehicle)

                        // Fuel chart
                        if let entries = vehicle.fuelEntries, !entries.isEmpty {
                            FuelEconomyChartView(entries: entries)
                        }

                        // Recent Activity
                        recentActivitySection(vehicle)

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 16)
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

    // MARK: - Vehicle Picker

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
            HStack(spacing: 10) {
                if let vehicle = selectedVehicle {
                    VehicleIconView(vehicle: vehicle)
                    Text(vehicle.displayName)
                        .font(Theme.Typography.headline)
                        .foregroundColor(.textPrimary)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(Theme.CornerRadius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.pill)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Hero Card

    private func heroCard(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Row 1: Greeting + Avatar + Search
            HStack {
                Text("Hello \(displayName)")
                    .font(Theme.Typography.title2)
                    .foregroundColor(.textPrimary)

                Spacer()

                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))

                // Profile avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryPurple, Color.pinkAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    if let photoURL = authService.userProfile?.photoURL,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(displayName.prefix(1).uppercased())
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        Text(displayName.prefix(1).uppercased())
                            .font(Theme.Typography.cardSubtitle)
                            .foregroundColor(.white)
                    }
                }
            }

            // Label
            Text("TODAY AVAILABLE")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)
                .tracking(1.5)

            // Split: Metric (left) + Car Image (right)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(vehicle.averageFuelEconomy.map { String(format: "%.1f", $0) } ?? "\u{2014}")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Km")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }

                    // Small indicator icon
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.primaryPurple)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }

                Spacer()

                // Car image — extends toward right edge
                CarImageView(
                    make: vehicle.make,
                    model: vehicle.model,
                    size: 160,
                    cornerRadius: 0
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.primaryPurple.opacity(0.6),
                                    Color.pinkAccent.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    // MARK: - Vehicle Info Strip

    private func vehicleInfoStrip(_ vehicle: Vehicle) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Car Number")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
                Text(vehicle.licensePlate ?? "\u{2014}")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text("Your Vehicle")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
                Text(vehicle.make)
                    .font(Theme.Typography.headline)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Stats Card

    private func statsCard(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total")
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)

            HStack(spacing: 12) {
                GradientStatCard(
                    icon: "fuelpump.fill",
                    value: formatCost(vehicle.totalFuelCost),
                    label: "Fuel Spent"
                )
                GradientStatCard(
                    icon: "wrench.and.screwdriver.fill",
                    value: formatCost(vehicle.totalMaintenanceCost),
                    label: "Service"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Gradient Stat Card

    private struct GradientStatCard: View {
        let icon: String
        let value: String
        let label: String

        var body: some View {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(Color.white.opacity(0.1))
                    )

                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryPurple.opacity(0.35),
                                Color.pinkAccent.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.primaryPurple.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Alerts Section

    @ViewBuilder
    private func alertsSection(_ vehicle: Vehicle) -> some View {
        let dueSchedules = (vehicle.maintenanceSchedules ?? []).filter {
            $0.isEnabled && $0.isDue(currentOdometer: vehicle.currentOdometer)
        }
        let expiringDocs = (vehicle.documents ?? []).filter {
            $0.isExpiringSoon || $0.isExpired
        }

        if !dueSchedules.isEmpty || !expiringDocs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Alerts")
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.textSecondary)

                VStack(spacing: 8) {
                    ForEach(dueSchedules) { schedule in
                        alertRow(
                            icon: "wrench.and.screwdriver.fill",
                            title: schedule.displayName,
                            subtitle: alertSubtitle(for: schedule, vehicle: vehicle),
                            color: .orange
                        )
                    }

                    ForEach(expiringDocs) { doc in
                        alertRow(
                            icon: "doc.text.fill",
                            title: doc.name,
                            subtitle: doc.isExpired ? "Expired" : "Expires soon",
                            color: doc.isExpired ? .red : .orange
                        )
                    }
                }
            }
            .darkCardStyle()
        }
    }

    private func alertSubtitle(for schedule: MaintenanceSchedule, vehicle: Vehicle) -> String {
        if let miles = schedule.milesUntilDue(currentOdometer: vehicle.currentOdometer), miles <= 0 {
            return "Overdue by \(Int(abs(miles))) \(vehicle.odometerUnit.abbreviation)"
        } else if let days = schedule.daysUntilDue(), days <= 0 {
            return "Overdue by \(abs(days)) days"
        } else if let days = schedule.daysUntilDue() {
            return "Due in \(days) days"
        }
        return "Service due"
    }

    private func alertRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(color)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Recent Activity (Unified)

    private func recentActivitySection(_ vehicle: Vehicle) -> some View {
        let items = buildActivityItems(vehicle)

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Recent Activity")
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)

            if items.isEmpty {
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
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.iconColor.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: item.icon)
                                .foregroundColor(item.iconColor)
                                .font(Theme.Typography.cardSubtitle)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.textPrimary)
                            Text(item.date.formatted(style: .medium))
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Text(item.value)
                            .font(Theme.Typography.cardSubtitle)
                            .foregroundColor(item.iconColor)
                    }
                    .padding(.vertical, Theme.Spacing.xs)

                    if index < items.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                }
            }
        }
        .darkCardStyle()
    }

    // MARK: - Helpers

    private func fuelTypeColor(_ vehicle: Vehicle) -> Color {
        switch vehicle.fuelType {
        case .electric, .hybrid, .plugInHybrid:
            return .greenAccent
        case .diesel:
            return .orange
        default:
            return .primaryPurple
        }
    }

    private func formatOdometer(_ value: Double) -> String {
        if value >= 100_000 {
            return String(format: "%.0fK", value / 1000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }

    private func formatCost(_ value: Double) -> String {
        if value >= 100_000 {
            return String(format: "\u{20B9}%.0fK", value / 1000)
        } else if value >= 1000 {
            return String(format: "\u{20B9}%.1fK", value / 1000)
        } else if value > 0 {
            return String(format: "\u{20B9}%.0f", value)
        }
        return "\u{20B9}0"
    }

    private struct ActivityItem: Identifiable {
        let id: UUID
        let icon: String
        let iconColor: Color
        let title: String
        let value: String
        let date: Date
    }

    private func buildActivityItems(_ vehicle: Vehicle) -> [ActivityItem] {
        var items: [ActivityItem] = []

        for entry in (vehicle.fuelEntries ?? []) {
            items.append(ActivityItem(
                id: entry.id,
                icon: "fuelpump.fill",
                iconColor: .greenAccent,
                title: "Fuel Fill-Up",
                value: entry.totalCost.asCurrency,
                date: entry.date
            ))
        }

        for record in (vehicle.maintenanceRecords ?? []) {
            items.append(ActivityItem(
                id: record.id,
                icon: "wrench.and.screwdriver.fill",
                iconColor: .primaryPurple,
                title: record.displayName,
                value: record.cost.asCurrency,
                date: record.date
            ))
        }

        for trip in (vehicle.trips ?? []).filter({ !$0.isActive }) {
            items.append(ActivityItem(
                id: trip.id,
                icon: "location.fill",
                iconColor: .pinkAccent,
                title: "\(trip.tripType.rawValue.capitalized) Trip",
                value: String(format: "%.1f km", trip.calculatedDistance),
                date: trip.date
            ))
        }

        for expense in (vehicle.expenses ?? []) {
            items.append(ActivityItem(
                id: expense.id,
                icon: expense.category.icon,
                iconColor: .expenseColor,
                title: expense.displayCategory,
                value: expense.amount.asCurrency,
                date: expense.date
            ))
        }

        return items.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
}

// MARK: - Supporting Views

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
    @State private var showingAddExpense = false

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

                QuickActionButton(
                    title: "Expense",
                    icon: "indianrupeesign.circle.fill",
                    color: .expenseColor
                ) {
                    showingAddExpense = true
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
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(vehicle: vehicle)
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

#Preview {
    DashboardView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
