import SwiftUI

struct VehicleHeroCard: View {
    let vehicle: Vehicle

    private var vehicleIcon: String {
        switch vehicle.fuelType {
        case .electric:
            return "bolt.car.fill"
        case .hybrid, .plugInHybrid:
            return "leaf.circle.fill"
        default:
            return "car.fill"
        }
    }

    private var fuelTypeColor: Color {
        switch vehicle.fuelType {
        case .electric:
            return .greenAccent
        case .hybrid, .plugInHybrid:
            return .greenAccent
        case .diesel:
            return .orange
        default:
            return .primaryPurple
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Vehicle image area
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                fuelTypeColor.opacity(0.3),
                                Color.cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Car image from bundled assets or placeholder
                if CarImageService.hasImage(make: vehicle.make, model: vehicle.model) {
                    CarImageView(
                        make: vehicle.make,
                        model: vehicle.model,
                        size: 160,
                        cornerRadius: Theme.CornerRadius.medium
                    )
                } else {
                    fallbackIcon
                }
            }
            .frame(height: 180)

            // Vehicle info
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    // Brand logo
                    BrandLogoView(
                        make: vehicle.make,
                        size: 44,
                        type: .icon,
                        fallbackIcon: vehicleIcon,
                        fallbackColor: fuelTypeColor
                    )
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.small)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(vehicle.displayName)
                            .font(Theme.Typography.cardTitle)
                            .foregroundColor(.textPrimary)

                        HStack(spacing: Theme.Spacing.sm) {
                            Text(String(vehicle.year))
                                .font(Theme.Typography.cardSubtitle)
                                .foregroundColor(.textSecondary)

                            if let plate = vehicle.licensePlate, !plate.isEmpty {
                                Text("•")
                                    .foregroundColor(.textSecondary)
                                Text(plate)
                                    .font(Theme.Typography.cardSubtitle)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    // Fuel type badge
                    Text(vehicle.fuelType.rawValue.capitalized)
                        .font(Theme.Typography.caption)
                        .foregroundColor(fuelTypeColor)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(fuelTypeColor.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.small)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Color.cardBackground)
        }
        .cornerRadius(Theme.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var fallbackIcon: some View {
        Image(systemName: vehicleIcon)
            .font(Theme.Typography.statValue)
            .foregroundStyle(
                LinearGradient(
                    colors: [fuelTypeColor, fuelTypeColor.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: fuelTypeColor.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        VehicleHeroCard(vehicle: Vehicle(
            name: "My Camry",
            make: "Toyota",
            model: "Camry",
            year: 2023,
            fuelType: .petrol
        ))
        .padding()
    }
}
