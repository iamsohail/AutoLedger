import SwiftUI
import SwiftData

struct AddMaintenanceRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var date = Date()
    @State private var odometer = ""
    @State private var serviceType: ServiceType = .oilChange
    @State private var customServiceName = ""
    @State private var totalCost = ""
    @State private var laborCost = ""
    @State private var partsCost = ""
    @State private var serviceProvider = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        TextField("Odometer", text: $odometer)
                            .keyboardType(.decimalPad)
                        Text(vehicle.odometerUnit.abbreviation)
                            .foregroundColor(.secondary)
                    }

                    Picker("Service Type", selection: $serviceType) {
                        ForEach(ServiceType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    if serviceType == .custom {
                        TextField("Custom Service Name", text: $customServiceName)
                    }
                }

                Section("Cost") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Total Cost", text: $totalCost)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Labor Cost (Optional)", text: $laborCost)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Parts Cost (Optional)", text: $partsCost)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Service Provider (Optional)") {
                    TextField("Shop/Mechanic Name", text: $serviceProvider)
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecord()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                odometer = String(format: "%.0f", vehicle.currentOdometer)
            }
        }
    }

    private var isValid: Bool {
        if serviceType == .custom && customServiceName.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    private func saveRecord() {
        let record = MaintenanceRecord(
            date: date,
            odometer: Double(odometer) ?? vehicle.currentOdometer,
            serviceType: serviceType,
            customServiceName: serviceType == .custom ? customServiceName : nil,
            cost: Double(totalCost) ?? 0,
            laborCost: Double(laborCost) ?? 0,
            partsCost: Double(partsCost) ?? 0,
            serviceProvider: serviceProvider.isEmpty ? nil : serviceProvider,
            notes: notes.isEmpty ? nil : notes
        )

        record.vehicle = vehicle

        if let odo = Double(odometer), odo > vehicle.currentOdometer {
            vehicle.currentOdometer = odo
        }
        vehicle.updatedAt = Date()

        modelContext.insert(record)
        dismiss()
    }
}

#Preview {
    AddMaintenanceRecordView(vehicle: Vehicle(
        name: "Test",
        make: "Toyota",
        model: "Camry",
        year: 2022
    ))
    .modelContainer(for: Vehicle.self, inMemory: true)
}
