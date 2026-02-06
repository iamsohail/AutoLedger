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
    @Namespace private var segmentAnimation

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom dark pill-style segmented picker
                HStack(spacing: 4) {
                    ForEach(LogSegment.allCases, id: \.self) { segment in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                selectedSegment = segment
                            }
                        } label: {
                            Text(segment.rawValue)
                                .font(Theme.Typography.subheadlineMedium)
                                .foregroundColor(selectedSegment == segment ? .white : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background {
                                    if selectedSegment == segment {
                                        Capsule()
                                            .fill(Color.primaryPurple)
                                            .matchedGeometryEffect(id: "segment", in: segmentAnimation)
                                    }
                                }
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
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
