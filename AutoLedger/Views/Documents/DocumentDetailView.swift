import SwiftUI
import SwiftData

struct DocumentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let document: Document

    @State private var showingDeleteConfirmation = false
    @State private var showingFullImage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Document image
                if let imageData = document.imageData, let uiImage = UIImage(data: imageData) {
                    Button {
                        showingFullImage = true
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(Theme.CornerRadius.medium)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(Color.cardBackground)
                            .frame(height: 150)
                        VStack(spacing: 8) {
                            Image(systemName: document.documentType.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.primaryPurple)
                            Text("No Image")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                // Metadata
                VStack(spacing: 12) {
                    metadataRow(label: "Type", value: document.documentType.displayName)
                    metadataRow(label: "Added", value: document.createdAt.formatted(style: .medium))

                    if let expDate = document.expirationDate {
                        HStack {
                            Text("Expires")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(expDate.formatted(style: .medium))
                                    .font(Theme.Typography.cardSubtitle)
                                    .foregroundColor(.textPrimary)
                                Text(expiryStatusText)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(expiryStatusColor)
                            }
                        }
                    }

                    if let notes = document.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                            Text(notes)
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .darkCardStyle()

                // Delete button
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Document")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(16)
        }
        .background(Color.darkBackground)
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog("Delete Document", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                NotificationService.shared.cancelNotification(id: "document_\(document.id.uuidString)")
                modelContext.delete(document)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this document?")
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageData = document.imageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                    Button {
                        showingFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
            }
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textPrimary)
        }
    }

    private var expiryStatusText: String {
        if document.isExpired {
            return "Expired"
        } else if let days = document.daysUntilExpiration {
            return "\(days) days remaining"
        }
        return "Valid"
    }

    private var expiryStatusColor: Color {
        if document.isExpired { return .red }
        if document.isExpiringSoon { return .orange }
        return .green
    }
}
