import SwiftUI

struct OnboardingView: View {
    @Binding var showingAddVehicle: Bool

    var body: some View {
        ZStack {
            // Dark background with gradient
            Color.darkBackground
                .ignoresSafeArea()

            // Purple gradient at top
            VStack {
                LinearGradient(
                    colors: [
                        Color.primaryPurple.opacity(0.4),
                        Color.primaryPurple.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                .ignoresSafeArea()

                Spacer()
            }

            // Content
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // App icon and title
                VStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryPurple, Color.pinkAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.primaryPurple.opacity(0.5), radius: 20, x: 0, y: 10)

                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }

                    Text("Auto Ledger")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text("Track fuel, maintenance, trips, and expenses for all your vehicles in one place.")
                        .font(Theme.Typography.cardSubtitle)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                }

                // Features
                VStack(spacing: Theme.Spacing.xs) {
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
                .padding(.horizontal, Theme.Spacing.md)

                Spacer()

                // CTA Button
                Button {
                    showingAddVehicle = true
                } label: {
                    Text("Add Your First Vehicle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.primaryPurple, Color.pinkAccent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Theme.CornerRadius.medium)
                        .shadow(color: Color.primaryPurple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }
}

#Preview {
    OnboardingView(showingAddVehicle: .constant(false))
}
