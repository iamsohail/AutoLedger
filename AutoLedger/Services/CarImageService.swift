import SwiftUI
import UIKit

/// Service for loading pre-generated car images from bundled assets
enum CarImageService {

    /// Get the asset name for a car image
    /// - Parameters:
    ///   - make: Vehicle manufacturer (e.g., "Hyundai")
    ///   - model: Vehicle model (e.g., "Creta")
    /// - Returns: Asset name for the car image
    static func assetName(make: String, model: String) -> String {
        let safeMake = make.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")

        let safeModel = model.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")

        return "\(safeMake)_\(safeModel)"
    }

    /// Check if a car image exists in assets
    static func hasImage(make: String, model: String) -> Bool {
        UIImage(named: assetName(make: make, model: model)) != nil
    }

    /// Load car image from assets
    static func loadImage(make: String, model: String) -> UIImage? {
        UIImage(named: assetName(make: make, model: model))
    }
}

// MARK: - SwiftUI View

struct CarImageView: View {
    let make: String
    let model: String
    var size: CGFloat = 200
    var cornerRadius: CGFloat = 16

    var body: some View {
        if let uiImage = CarImageService.loadImage(make: make, model: model) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: size)
                .cornerRadius(cornerRadius)
        } else {
            // Placeholder when image not available
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .frame(height: size)

                VStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(.textSecondary.opacity(0.4))

                    Text("\(make) \(model)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CarImageView(make: "Hyundai", model: "Creta", size: 200)
        CarImageView(make: "Tata", model: "Nexon", size: 200)
    }
    .padding()
    .background(Color.darkBackground)
}
