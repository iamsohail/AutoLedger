import SwiftUI
import MapKit

struct ParkingSpotDetailView: View {
    let spot: ParkingSpot

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map with pin
                Map {
                    Marker(
                        spot.address ?? "My Spot",
                        systemImage: "p.square.fill",
                        coordinate: CLLocationCoordinate2D(
                            latitude: spot.latitude,
                            longitude: spot.longitude
                        )
                    )
                    .tint(Color.primaryPurple)
                }
                .frame(height: 250)
                .cornerRadius(Theme.CornerRadius.medium)

                // Photo
                if let photoData = spot.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(Theme.CornerRadius.medium)
                }

                // Details
                VStack(spacing: 12) {
                    if let address = spot.address {
                        detailRow(icon: "location.fill", label: "Address", value: address)
                    }
                    if let floor = spot.floor {
                        detailRow(icon: "building.2.fill", label: "Floor", value: floor)
                    }
                    if let spotNum = spot.spotNumber {
                        detailRow(icon: "number", label: "Spot", value: spotNum)
                    }
                    detailRow(icon: "clock.fill", label: "Saved", value: spot.timestamp.formatted(style: .medium))
                    if let vehicle = spot.vehicle {
                        detailRow(icon: "car.fill", label: "Vehicle", value: vehicle.displayName)
                    }
                    if let notes = spot.notes, !notes.isEmpty {
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

                // Get Directions button
                Button {
                    let coordinate = CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
                    let placemark = MKPlacemark(coordinate: coordinate)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = spot.address ?? "Parking Spot"
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Get Directions")
                    }
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primaryPurple)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(16)
        }
        .background(Color.darkBackground)
        .navigationTitle("Parking Spot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.darkBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.primaryPurple)
                .frame(width: 24)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textPrimary)
        }
    }
}
