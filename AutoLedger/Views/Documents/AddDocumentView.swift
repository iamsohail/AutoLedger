import SwiftUI
import SwiftData
import PhotosUI

struct AddDocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let vehicle: Vehicle

    @State private var name = ""
    @State private var documentType: DocumentType = .insuranceCard
    @State private var hasExpiration = false
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var notes = ""
    @State private var documentImage: UIImage?
    @State private var showingScanner = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Info") {
                    TextField("Document Name", text: $name)
                        .darkListRowStyle()

                    Picker("Type", selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .darkListRowStyle()
                    .onChange(of: documentType) { _, newType in
                        hasExpiration = newType.hasExpiration
                    }
                }

                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpiration)
                        .tint(.primaryPurple)
                        .darkListRowStyle()

                    if hasExpiration {
                        DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                            .darkListRowStyle()
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .darkListRowStyle()
                }

                Section("Document Image") {
                    if let image = documentImage {
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
                        Label("Scan Document", systemImage: "doc.text.viewfinder")
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
            .navigationTitle("Add Document")
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
                    Button("Save") { saveDocument() }
                        .foregroundColor(.primaryPurple)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView(
                    onScan: { image in
                        documentImage = image
                        showingScanner = false
                    },
                    onCancel: { showingScanner = false }
                )
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        documentImage = image
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationErrorMessage)
            }
            .onAppear {
                hasExpiration = documentType.hasExpiration
            }
        }
    }

    private func saveDocument() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationErrorMessage = "Please enter a document name."
            showingValidationError = true
            return
        }

        let document = Document(
            name: name.trimmingCharacters(in: .whitespaces),
            documentType: documentType,
            expirationDate: hasExpiration ? expirationDate : nil,
            notes: notes.isEmpty ? nil : notes
        )
        document.imageData = documentImage?.jpegData(compressionQuality: 0.7)
        document.vehicle = vehicle
        modelContext.insert(document)

        // Schedule expiry notification
        if hasExpiration {
            NotificationService.shared.scheduleDocumentExpirationReminder(
                id: document.id.uuidString,
                documentName: document.name,
                expirationDate: expirationDate
            )
        }

        dismiss()
    }
}
