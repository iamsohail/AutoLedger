import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components)!
    }

    var startOfYear: Date {
        let components = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: components)!
    }

    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }

    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isThisMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.month, from: self) == calendar.component(.month, from: now) &&
               calendar.component(.year, from: self) == calendar.component(.year, from: now)
    }

    var isThisYear: Bool {
        Calendar.current.component(.year, from: self) == Calendar.current.component(.year, from: Date())
    }
}

// MARK: - Double Extensions

extension Double {
    func formatted(as style: NumberFormatter.Style, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.maximumFractionDigits = maximumFractionDigits
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.\(maximumFractionDigits)f", self)
    }

    var asCurrency: String {
        formatted(as: .currency)
    }

    var asDecimal: String {
        formatted(as: .decimal)
    }

    func asMileage(unit: OdometerUnit) -> String {
        "\(formatted(as: .decimal, maximumFractionDigits: 1)) \(unit.abbreviation)"
    }

    func asFuelEconomy(odometerUnit: OdometerUnit, volumeUnit: VolumeUnit) -> String {
        let value = formatted(as: .decimal, maximumFractionDigits: 1)
        if odometerUnit == .miles && volumeUnit == .gallons {
            return "\(value) MPG"
        } else if odometerUnit == .kilometers && volumeUnit == .liters {
            // Convert to L/100km
            let lPer100km = 100.0 / self
            return "\(lPer100km.formatted(as: .decimal, maximumFractionDigits: 1)) L/100km"
        }
        return "\(value) \(odometerUnit.abbreviation)/\(volumeUnit.abbreviation)"
    }
}

// MARK: - Color Extensions

extension Color {
    static let appPrimary = Color("AccentColor")
    static let fuelColor = Color.orange
    static let maintenanceColor = Color.blue
    static let tripColor = Color.green
    static let expenseColor = Color.red
    static let documentColor = Color.purple

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    func sectionHeaderStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    func element(withId id: Element.ID) -> Element? {
        first { $0.id == id }
    }
}
