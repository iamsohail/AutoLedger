import SwiftUI

struct DarkFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color = .primaryPurple

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.cardSubtitle)
                    .foregroundColor(.textPrimary)
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        VStack(spacing: 0) {
            DarkFeatureRow(
                icon: "fuelpump.fill",
                title: "Fuel Tracking",
                description: "Log fill-ups and track MPG",
                iconColor: .greenAccent
            )
            DarkFeatureRow(
                icon: "wrench.and.screwdriver.fill",
                title: "Maintenance",
                description: "Schedule and track services",
                iconColor: .primaryPurple
            )
            DarkFeatureRow(
                icon: "map.fill",
                title: "Trip Logging",
                description: "Track business and personal trips",
                iconColor: .pinkAccent
            )
            DarkFeatureRow(
                icon: "chart.bar.fill",
                title: "Analytics",
                description: "View costs and trends",
                iconColor: .orange
            )
        }
        .padding()
    }
}
