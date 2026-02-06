import SwiftUI
import SwiftData

struct VaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedVehicle: Vehicle?
    @State private var showingAddDocument = false
    @State private var selectedFilter: DocumentType?
    @State private var showAsGrid = true

    private var documents: [Document] {
        guard let vehicle = selectedVehicle else { return [] }
        let docs = vehicle.documents ?? []
        if let filter = selectedFilter {
            return docs.filter { $0.documentType == filter }.sorted { $0.createdAt > $1.createdAt }
        }
        return docs.sorted { $0.createdAt > $1.createdAt }
    }

    private var expiringDocuments: [Document] {
        guard let vehicle = selectedVehicle else { return [] }
        return (vehicle.documents ?? []).filter { $0.isExpired || $0.isExpiringSoon }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if selectedVehicle != nil {
                    VStack(spacing: 16) {
                        // Expiry alerts banner
                        if !expiringDocuments.isEmpty {
                            expiryAlertsBanner
                        }

                        // Filter chips
                        filterChips

                        // Grid/List toggle
                        HStack {
                            Text("\(documents.count) Documents")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Button {
                                withAnimation { showAsGrid.toggle() }
                            } label: {
                                Image(systemName: showAsGrid ? "square.grid.2x2.fill" : "list.bullet")
                                    .foregroundColor(.primaryPurple)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Content
                        if documents.isEmpty {
                            emptyState
                        } else if showAsGrid {
                            gridContent
                        } else {
                            listContent
                        }
                    }
                    .padding(.top, 8)
                } else {
                    ContentUnavailableView(
                        "No Vehicle Selected",
                        systemImage: "car.fill",
                        description: Text("Select a vehicle to view documents")
                    )
                }
            }
            .background(Color.darkBackground)
            .navigationTitle("Vault")
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDocument = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(selectedVehicle == nil)
                }
            }
            .sheet(isPresented: $showingAddDocument) {
                if let vehicle = selectedVehicle {
                    AddDocumentView(vehicle: vehicle)
                }
            }
        }
    }

    // MARK: - Expiry Alerts Banner

    private var expiryAlertsBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Document Alerts")
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.textPrimary)
            }

            ForEach(expiringDocuments) { doc in
                HStack(spacing: 8) {
                    Circle()
                        .fill(doc.isExpired ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(doc.name)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(doc.isExpired ? "Expired" : "\(doc.daysUntilExpiration ?? 0)d left")
                        .font(Theme.Typography.caption)
                        .foregroundColor(doc.isExpired ? .red : .orange)
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(DocumentType.allCases, id: \.self) { type in
                    FilterChip(title: type.displayName, isSelected: selectedFilter == type) {
                        selectedFilter = (selectedFilter == type) ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(documents) { doc in
                NavigationLink {
                    DocumentDetailView(document: doc)
                } label: {
                    DocumentGridCard(document: doc)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - List Content

    private var listContent: some View {
        LazyVStack(spacing: 8) {
            ForEach(documents) { doc in
                NavigationLink {
                    DocumentDetailView(document: doc)
                } label: {
                    DocumentListRow(document: doc)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 50))
                .foregroundColor(.textSecondary.opacity(0.5))
            Text("No Documents")
                .font(Theme.Typography.headline)
                .foregroundColor(.textPrimary)
            Text("Store insurance, registration, PUC, and other vehicle documents securely.")
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showingAddDocument = true
            } label: {
                Text("Add Document")
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.primaryPurple)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryPurple : Color.cardBackground)
                .cornerRadius(Theme.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.pill)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Document Grid Card

struct DocumentGridCard: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: document.documentType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(expiryColor)
                Spacer()
                if document.expirationDate != nil {
                    expiryBadge
                }
            }

            if let imageData = document.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 80)
                    .clipped()
                    .cornerRadius(6)
            }

            Text(document.name)
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textPrimary)
                .lineLimit(2)

            Text(document.documentType.displayName)
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(expiryBorderColor, lineWidth: 1)
        )
    }

    private var expiryColor: Color {
        if document.isExpired { return .red }
        if document.isExpiringSoon { return .orange }
        return .primaryPurple
    }

    private var expiryBorderColor: Color {
        if document.isExpired { return .red.opacity(0.5) }
        if document.isExpiringSoon { return .orange.opacity(0.4) }
        return Color.white.opacity(0.05)
    }

    @ViewBuilder
    private var expiryBadge: some View {
        if document.isExpired {
            Text("Expired")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red)
                .cornerRadius(4)
        } else if document.isExpiringSoon {
            Text("\(document.daysUntilExpiration ?? 0)d")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .cornerRadius(4)
        } else {
            Text("Valid")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green)
                .cornerRadius(4)
        }
    }
}

// MARK: - Document List Row

struct DocumentListRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.documentType.icon)
                .font(.system(size: 18))
                .foregroundColor(document.isExpired ? .red : (document.isExpiringSoon ? .orange : .primaryPurple))
                .frame(width: 36, height: 36)
                .background(
                    Circle().fill(
                        (document.isExpired ? Color.red : (document.isExpiringSoon ? Color.orange : Color.primaryPurple))
                            .opacity(0.15)
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.textPrimary)
                Text(document.documentType.displayName)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            if let days = document.daysUntilExpiration {
                Text(days < 0 ? "Expired" : "\(days)d left")
                    .font(Theme.Typography.caption)
                    .foregroundColor(days < 0 ? .red : (days <= 30 ? .orange : .green))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    VaultView(selectedVehicle: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
