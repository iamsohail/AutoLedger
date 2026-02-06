import SwiftUI
import SwiftData
import PhotosUI

struct SaveParkingSpotView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService.shared

    @Query(filter: #Predicate<Vehicle> { $0.isActive }, sort: \Vehicle.createdAt, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var selectedVehicle: Vehicle?
    @State private var floor = ""
    @State private var spotNumber = ""
    @State private var notes = ""
    @State private var address: String?
    @State private var photoImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                locationSection
                detailsSection
                notesSection
                photoSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .navigationTitle("Save Parking Spot")
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
                    Button("Save") { saveParkingSpot() }
                        .foregroundColor(.primaryPurple)
                        .fontWeight(.semibold)
                        .disabled(locationService.currentLocation == nil || isSaving)
                }
            }
            .onAppear {
                locationService.requestPermission()
                locationService.requestLocation()
                selectedVehicle = vehicles.first
            }
            .onChange(of: locationService.currentLocation?.latitude) { _, _ in
                guard let loc = locationService.currentLocation, address == nil else { return }
                Task {
                    address = await locationService.reverseGeocode(location: loc)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photoImage = image
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var locationSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryPurple)

                locationLabel
            }
            .darkListRowStyle()
        } header: {
            Text("Current Location")
                .foregroundColor(.textSecondary)
        }
    }

    @ViewBuilder
    private var locationLabel: some View {
        if let address = address {
            Text(address)
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textPrimary)
        } else if locationService.currentLocation != nil {
            HStack(spacing: 8) {
                ProgressView().tint(.primaryPurple)
                Text("Getting address...")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }
        } else {
            Text("Location unavailable")
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
        }
    }

    private var detailsSection: some View {
        Section {
            Picker("Vehicle", selection: $selectedVehicle) {
                Text("None").tag(nil as Vehicle?)
                ForEach(vehicles) { vehicle in
                    Text(vehicle.displayName).tag(vehicle as Vehicle?)
                }
            }
            .darkListRowStyle()

            TextField("Floor / Level (optional)", text: $floor)
                .darkListRowStyle()

            TextField("Spot Number (optional)", text: $spotNumber)
                .darkListRowStyle()
        } header: {
            Text("Details")
                .foregroundColor(.textSecondary)
        }
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 60)
                .darkListRowStyle()
        } header: {
            Text("Notes")
                .foregroundColor(.textSecondary)
        }
    }

    private var photoSection: some View {
        Section {
            if let image = photoImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .cornerRadius(8)
                    .darkListRowStyle()
            }

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                Label("Add Photo", systemImage: "camera")
            }
            .darkListRowStyle()
        } header: {
            Text("Photo")
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Save

    private func saveParkingSpot() {
        guard let location = locationService.currentLocation else { return }
        isSaving = true

        let spot = ParkingSpot(
            latitude: location.latitude,
            longitude: location.longitude,
            address: address,
            floor: floor.isEmpty ? nil : floor,
            spotNumber: spotNumber.isEmpty ? nil : spotNumber,
            notes: notes.isEmpty ? nil : notes
        )
        spot.photoData = photoImage?.jpegData(compressionQuality: 0.7)
        spot.vehicle = selectedVehicle
        modelContext.insert(spot)
        dismiss()
    }
}
