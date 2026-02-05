import SwiftUI

// MARK: - Theme Constants

enum Theme {
    // MARK: - Typography
    enum Typography {
        // Titles
        static let largeTitle: Font = .system(size: 34, weight: .bold)
        static let title: Font = .system(size: 28, weight: .bold)
        static let title2: Font = .system(size: 22, weight: .bold)
        static let title3: Font = .system(size: 20, weight: .semibold)

        // Headlines & Body
        static let headline: Font = .system(size: 17, weight: .semibold)
        static let body: Font = .system(size: 17, weight: .regular)
        static let bodyMedium: Font = .system(size: 17, weight: .medium)
        static let bodyBold: Font = .system(size: 17, weight: .bold)

        // Subheadlines
        static let subheadline: Font = .system(size: 15, weight: .regular)
        static let subheadlineMedium: Font = .system(size: 15, weight: .medium)
        static let subheadlineSemibold: Font = .system(size: 15, weight: .semibold)

        // Small Text
        static let footnote: Font = .system(size: 13, weight: .regular)
        static let caption: Font = .system(size: 12, weight: .regular)
        static let captionMedium: Font = .system(size: 12, weight: .medium)
        static let caption2: Font = .system(size: 11, weight: .regular)

        // Stats (rounded design)
        static let statValue: Font = .system(size: 48, weight: .bold, design: .rounded)
        static let statValueMedium: Font = .system(size: 36, weight: .bold, design: .rounded)
        static let statValueSmall: Font = .system(size: 24, weight: .bold, design: .rounded)

        // Special
        static let greeting: Font = .system(size: 24, weight: .semibold)
        static let cardTitle: Font = .system(size: 18, weight: .semibold)
        static let cardSubtitle: Font = .system(size: 14, weight: .medium)
        static let label: Font = .system(size: 12, weight: .medium)

        // Icons
        static let iconLarge: Font = .system(size: 50)
        static let iconMedium: Font = .system(size: 40)
        static let iconSmall: Font = .system(size: 22)
        static let iconTiny: Font = .system(size: 18)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows
    enum Shadow {
        static let cardShadow = Color.black.opacity(0.3)
        static let cardShadowRadius: CGFloat = 10
    }

    // MARK: - Gradients
    static var purpleGradient: LinearGradient {
        LinearGradient(
            colors: [Color("PurpleGradientStart"), Color("PurpleGradientEnd")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkGradient: LinearGradient {
        LinearGradient(
            colors: [Color("CardBackground"), Color("DarkBackground")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var primaryPurpleGradient: LinearGradient {
        LinearGradient(
            colors: [Color("PrimaryPurple").opacity(0.8), Color("PrimaryPurple")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Dark Mode Colors

extension Color {
    static let primaryPurple = Color("PrimaryPurple")
    static let greenAccent = Color("GreenAccent")
    static let pinkAccent = Color("PinkAccent")
    static let darkBackground = Color("DarkBackground")
    static let cardBackground = Color("CardBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let purpleGradientStart = Color("PurpleGradientStart")
    static let purpleGradientEnd = Color("PurpleGradientEnd")
}

// MARK: - View Modifiers

extension View {
    func darkCardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }

    func gradientCardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryPurple.opacity(0.15), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Color.primaryPurple.opacity(0.3), lineWidth: 1)
            )
    }

    func quickActionStyle(color: Color) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(color.opacity(0.15))
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }

    func darkListRowStyle() -> some View {
        self
            .listRowBackground(Color.cardBackground)
            .listRowSeparatorTint(Color.white.opacity(0.1))
    }

    func darkNavigationStyle() -> some View {
        self
            .toolbarBackground(Color.darkBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
