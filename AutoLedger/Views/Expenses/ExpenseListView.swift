import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddExpense = false
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false

    private var expenses: [Expense] {
        guard let vehicle = selectedVehicle else { return [] }
        return (vehicle.expenses ?? []).sorted { $0.date > $1.date }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var thisMonthTotal: Double {
        expenses.filter { $0.date.isThisMonth }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if selectedVehicle != nil {
                List {
                    Section {
                        ExpenseSummaryRow(total: totalExpenses, thisMonth: thisMonthTotal)
                    }

                    Section("Expenses") {
                        if expenses.isEmpty {
                            Text("No Expenses Yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(expenses) { expense in
                                ExpenseRowView(expense: expense)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            expenseToDelete = expense
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
                    description: Text("Select a vehicle to view expenses")
                )
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            if let vehicle = selectedVehicle {
                AddExpenseView(vehicle: vehicle)
            }
        }
        .confirmationDialog(
            "Delete Expense",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let expense = expenseToDelete {
                    modelContext.delete(expense)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this expense?")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedVehicle == nil)
            }
        }
    }
}

// MARK: - Summary Row

struct ExpenseSummaryRow: View {
    let total: Double
    let thisMonth: Double

    var body: some View {
        HStack(spacing: 24) {
            SummaryStatView(
                title: "Total Spent",
                value: total.asCurrency,
                color: .expenseColor
            )
            SummaryStatView(
                title: "This Month",
                value: thisMonth.asCurrency,
                color: .orange
            )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Expense Row

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .font(Theme.Typography.title2)
                .foregroundColor(.expenseColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.displayCategory)
                    .font(Theme.Typography.headline)
                HStack {
                    Text(expense.date.formatted(style: .medium))
                    if let vendor = expense.vendor, !vendor.isEmpty {
                        Text("\u{2022}")
                        Text(vendor)
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(expense.amount.asCurrency)
                .font(Theme.Typography.headline)
        }
        .padding(.vertical, 4)
    }
}
