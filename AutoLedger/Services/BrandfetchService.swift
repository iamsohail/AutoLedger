import SwiftUI

/// Service for car brand logos - uses local assets with consistent fallback
class CarBrandLogoService {
    static let shared = CarBrandLogoService()

    private init() {}

    // MARK: - Detailed Logos (render with original colors)

    /// Brands whose assets contain multiple distinct colors that benefit from original rendering
    private let detailedLogoBrands: Set<String> = [
        "bmw",              // Black + white quadrant roundel
        "datsun",           // Multi-color 3D badge PNG
        "porsche",          // Detailed crest
        "bentley",          // White wings + dark B detail SVG
    ]

    /// Check if a brand should render with original colors
    func isDetailedLogo(for make: String) -> Bool {
        let normalized = make.lowercased().trimmingCharacters(in: .whitespaces)
        return detailedLogoBrands.contains(normalized)
    }

    // MARK: - Brand Colors (for consistent fallback styling)

    /// Brand-specific colors for initials fallback
    private let brandColors: [String: Color] = [
        // Indian Brands
        "maruti": Color(red: 0.0, green: 0.31, blue: 0.63),      // Blue
        "tata": Color(red: 0.0, green: 0.22, blue: 0.47),        // Dark Blue
        "mahindra": Color(red: 0.8, green: 0.0, blue: 0.0),      // Red

        // Japanese Brands
        "honda": Color(red: 0.8, green: 0.0, blue: 0.0),         // Red
        "toyota": Color(red: 0.8, green: 0.0, blue: 0.0),        // Red
        "suzuki": Color(red: 0.0, green: 0.31, blue: 0.63),      // Blue
        "nissan": Color(red: 0.75, green: 0.75, blue: 0.75),     // Silver
        "mazda": Color(red: 0.6, green: 0.6, blue: 0.6),         // Gray

        // Korean Brands
        "hyundai": Color(red: 0.0, green: 0.27, blue: 0.53),     // Blue
        "kia": Color(red: 0.73, green: 0.0, blue: 0.15),         // Red

        // German Brands
        "volkswagen": Color(red: 0.0, green: 0.22, blue: 0.47),  // Dark Blue
        "bmw": Color(red: 0.0, green: 0.47, blue: 0.73),         // Blue
        "mercedes": Color(red: 0.6, green: 0.6, blue: 0.6),      // Silver
        "audi": Color(red: 0.6, green: 0.6, blue: 0.6),          // Silver
        "porsche": Color(red: 0.8, green: 0.0, blue: 0.0),       // Red
        "skoda": Color(red: 0.0, green: 0.47, blue: 0.27),       // Green

        // American Brands
        "ford": Color(red: 0.0, green: 0.22, blue: 0.47),        // Blue
        "chevrolet": Color(red: 0.85, green: 0.65, blue: 0.0),   // Gold
        "jeep": Color(red: 0.0, green: 0.31, blue: 0.0),         // Green
        "tesla": Color(red: 0.8, green: 0.0, blue: 0.0),         // Red

        // British Brands
        "jaguar": Color(red: 0.0, green: 0.31, blue: 0.0),       // Green
        "land rover": Color(red: 0.0, green: 0.31, blue: 0.0),   // Green
        "mg": Color(red: 0.8, green: 0.0, blue: 0.0),            // Red

        // Italian Brands
        "ferrari": Color(red: 0.8, green: 0.0, blue: 0.0),       // Red
        "lamborghini": Color(red: 0.85, green: 0.65, blue: 0.0), // Gold

        // French Brands
        "renault": Color(red: 0.85, green: 0.65, blue: 0.0),     // Gold

        // Chinese Brands
        "byd": Color(red: 0.0, green: 0.31, blue: 0.63),         // Blue
    ]

    /// Get brand color for fallback
    func brandColor(for make: String) -> Color {
        let normalized = make.lowercased().trimmingCharacters(in: .whitespaces)
        return brandColors[normalized] ?? .primaryPurple
    }

    /// Get initials for brand (1-2 characters)
    func brandInitials(for make: String) -> String {
        let words = make.uppercased().split(separator: " ")
        if words.count >= 2 {
            // Two words: first letter of each (e.g., "Land Rover" -> "LR")
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        } else if make.count >= 2 {
            // Single word: first two letters (e.g., "Toyota" -> "TO")
            return String(make.uppercased().prefix(2))
        } else {
            return String(make.uppercased().prefix(1))
        }
    }

    /// Overrides for brand names that don't match asset filenames after normalization
    private let assetNameOverrides: [String: String] = [
        "mini": "Mini",
    ]

    /// Asset name for bundled logo (if exists)
    func assetName(for make: String) -> String {
        let lower = make.lowercased().trimmingCharacters(in: .whitespaces)
        if let override = assetNameOverrides[lower] {
            return override
        }
        // Strip diacritics (ë→e, š→s) and normalize spaces/hyphens to underscores
        return make.folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Check if local asset exists
    func hasLocalAsset(for make: String) -> Bool {
        UIImage(named: assetName(for: make)) != nil
    }
}

// MARK: - SwiftUI View for Brand Logo

struct BrandLogoView: View {
    let make: String
    var size: CGFloat = 40
    var type: LogoType = .icon
    var fallbackIcon: String = "car.fill"
    var fallbackColor: Color = .primaryPurple

    enum LogoType {
        case icon
        case symbol
        case logo
    }

    private let service = CarBrandLogoService.shared

    private var assetName: String {
        service.assetName(for: make)
    }

    var body: some View {
        if service.hasLocalAsset(for: make) {
            if service.isDetailedLogo(for: make) {
                // Detailed logos: desaturated to monochrome on black background
                ZStack {
                    Circle()
                        .fill(Color.black)

                    Image(assetName)
                        .resizable()
                        .renderingMode(.original)
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(size * 0.18)
                        .grayscale(1.0)
                        .contrast(1.3)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                // Simple logos: white template on black circle
                ZStack {
                    Circle()
                        .fill(Color.black)

                    Image(assetName)
                        .resizable()
                        .renderingMode(.template)
                        .interpolation(.high)
                        .foregroundColor(.white)
                        .scaledToFit()
                        .padding(size * 0.18)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            }
        } else {
            // Initials fallback
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(service.brandColor(for: make).opacity(0.15))

            Text(service.brandInitials(for: make))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(service.brandColor(for: make))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Simple Logos (White Template)")
            .font(.headline)
            .foregroundColor(.white)

        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(["Toyota", "Honda", "BMW", "Audi", "Hyundai", "Kia", "Ford", "Tata"], id: \.self) { brand in
                VStack(spacing: 8) {
                    BrandLogoView(make: brand, size: 50)
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }

        Text("Detailed Logos (Original Colors)")
            .font(.headline)
            .foregroundColor(.white)

        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(["Porsche", "BMW", "Mercedes-Benz", "Maruti Suzuki", "MG", "Mitsubishi", "Volkswagen", "Hyundai"], id: \.self) { brand in
                VStack(spacing: 8) {
                    BrandLogoView(make: brand, size: 50)
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    .padding()
    .background(Color.darkBackground)
}
