import SwiftUI
import MapKit

struct ExploreView: View {
    @StateObject private var locationService = LocationService.shared

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedCategory: StationCategory = .fuel
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSaveParkingSpot = false
    @State private var selectedMapItem: MKMapItem?

    enum StationCategory: String, CaseIterable {
        case fuel = "Fuel Stations"
        case ev = "EV Charging"
        case cng = "CNG Pumps"
        case parking = "Parking"

        var searchQuery: String {
            switch self {
            case .fuel: return "petrol pump"
            case .ev: return "EV charging station"
            case .cng: return "CNG pump"
            case .parking: return "parking"
            }
        }

        var icon: String {
            switch self {
            case .fuel: return "fuelpump.fill"
            case .ev: return "bolt.car.fill"
            case .cng: return "flame.fill"
            case .parking: return "p.square.fill"
            }
        }

        var color: Color {
            switch self {
            case .fuel: return .orange
            case .ev: return .greenAccent
            case .cng: return .blue
            case .parking: return .primaryPurple
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map
                Map(position: $cameraPosition, selection: $selectedMapItem) {
                    UserAnnotation()

                    ForEach(searchResults, id: \.self) { item in
                        Marker(
                            item.name ?? "Unknown",
                            systemImage: selectedCategory.icon,
                            coordinate: item.placemark.coordinate
                        )
                        .tint(selectedCategory.color)
                        .tag(item)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }

                // Category filters overlay
                VStack(spacing: 0) {
                    categoryFilters
                        .padding(.top, 8)

                    Spacer()

                    // Bottom buttons
                    HStack(spacing: 12) {
                        // Save My Spot button
                        Button {
                            showingSaveParkingSpot = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Save My Spot")
                                    .font(Theme.Typography.cardSubtitle)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.primaryPurple)
                            .cornerRadius(Theme.CornerRadius.pill)
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                        }

                        Spacer()

                        // Search this area
                        if !isSearching {
                            Button {
                                searchArea()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search Area")
                                        .font(Theme.Typography.cardSubtitle)
                                }
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.cardBackground)
                                .cornerRadius(Theme.CornerRadius.pill)
                                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                            }
                        } else {
                            ProgressView()
                                .tint(.primaryPurple)
                                .padding(10)
                                .background(Color.cardBackground)
                                .cornerRadius(Theme.CornerRadius.pill)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                locationService.requestPermission()
            }
            .onChange(of: selectedCategory) { _, _ in
                searchArea()
            }
            .sheet(isPresented: $showingSaveParkingSpot) {
                SaveParkingSpotView()
            }
            .sheet(item: $selectedMapItem) { item in
                mapItemDetail(item)
            }
        }
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StationCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.rawValue)
                                .font(Theme.Typography.captionMedium)
                        }
                        .foregroundColor(selectedCategory == category ? .white : .textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? category.color : Color.cardBackground)
                        .cornerRadius(Theme.CornerRadius.pill)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Map Item Detail

    private func mapItemDetail(_ item: MKMapItem) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: selectedCategory.icon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedCategory.color)
                        .frame(width: 48, height: 48)
                        .background(selectedCategory.color.opacity(0.15))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name ?? "Unknown")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.textPrimary)
                        if let phone = item.phoneNumber {
                            Text(phone)
                                .font(Theme.Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                }

                if let address = item.placemark.title {
                    Text(address)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    item.openInMaps(launchOptions: [
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
                    .padding(.vertical, 12)
                    .background(Color.primaryPurple)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(20)
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
            .background(Color.darkBackground)
        }
    }

    // MARK: - Search

    private func searchArea() {
        guard let location = locationService.currentLocation else { return }
        isSearching = true

        let region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )

        Task {
            searchResults = await locationService.searchNearby(
                query: selectedCategory.searchQuery,
                region: region
            )
            isSearching = false
        }
    }
}

// MKMapItem needs Identifiable conformance for sheet(item:)
extension MKMapItem: @retroactive Identifiable {
    public var id: String {
        "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude),\(name ?? "")"
    }
}

#Preview {
    ExploreView()
}
