import SwiftUI

struct LogView: View {
    @Binding var selectedVehicle: Vehicle?

    enum LogSegment: String, CaseIterable {
        case fuel = "Fuel"
        case service = "Service"
        case expenses = "Expenses"
        case trips = "Trips"
    }

    @State private var selectedSegment: LogSegment = .fuel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("Log Type", selection: $selectedSegment) {
                    ForEach(LogSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Content
                Group {
                    switch selectedSegment {
                    case .fuel:
                        FuelLogContentView(selectedVehicle: $selectedVehicle)
                    case .service:
                        MaintenanceContentView(selectedVehicle: $selectedVehicle)
                    case .expenses:
                        ExpenseListView(selectedVehicle: $selectedVehicle)
                    case .trips:
                        TripContentView(selectedVehicle: $selectedVehicle)
                    }
                }
            }
            .background(Color.darkBackground)
            .navigationTitle("Log")
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    LogView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
