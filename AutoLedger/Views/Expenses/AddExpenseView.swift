import SwiftUI
import SwiftData
import PhotosUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var date = Date()
    @State private var category: ExpenseCategory = .parking
    @State private var customCategoryName = ""
    @State private var amount = ""
    @State private var vendor = ""
    @State private var expenseDescription = ""
    @State private var notes = ""
    @State private var receiptImage: UIImage?
    @State private var showingScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .darkListRowStyle()

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .darkListRowStyle()

                    if category == .other {
                        TextField("Custom Category", text: $customCategoryName)
                            .darkListRowStyle()
                    }

                    HStack {
                        Text("\u{20B9}")
                            .foregroundColor(.textSecondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    .darkListRowStyle()

                    TextField("Vendor (optional)", text: $vendor)
                        .darkListRowStyle()

                    TextField("Description (optional)", text: $expenseDescription)
                        .darkListRowStyle()
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .darkListRowStyle()
                }

                Section("Receipt") {
                    if let image = receiptImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .darkListRowStyle()
                    }

                    Button {
                        showingScanner = true
                    } label: {
                        Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                    }
                    .darkListRowStyle()

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Label("Choose from Photos", systemImage: "photo")
                    }
                    .darkListRowStyle()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primaryPurple)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExpense() }
                        .foregroundColor(.primaryPurple)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(
                    onScan: { image in
                        receiptImage = image
                        showingScanner = false
                    },
                    onCancel: { showingScanner = false }
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        receiptImage = image
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
        }
    }

    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            validationErrorMessage = "Please enter a valid amount."
            showingValidationError = true
            return
        }

        let expense = Expense(
            date: date,
            category: category,
            customCategoryName: category == .other ? customCategoryName : nil,
            amount: amountValue,
            vendor: vendor.isEmpty ? nil : vendor,
            description: expenseDescription.isEmpty ? nil : expenseDescription,
            notes: notes.isEmpty ? nil : notes
        )
        expense.receiptImageData = receiptImage?.jpegData(compressionQuality: 0.7)
        expense.vehicle = vehicle
        modelContext.insert(expense)
        dismiss()
    }
}
