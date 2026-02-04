import SwiftUI

struct OnboardingView: View {
    @Binding var showingAddVehicle: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)

                Text("Auto Ledger")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track fuel, maintenance, trips, and expenses for all your vehicles in one place.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                FeatureRow(icon: "fuelpump.fill", title: "Fuel Tracking", description: "Log fill-ups and track MPG")
                FeatureRow(icon: "wrench.and.screwdriver.fill", title: "Maintenance", description: "Schedule and track services")
                FeatureRow(icon: "map.fill", title: "Trip Logging", description: "Track business and personal trips")
                FeatureRow(icon: "chart.bar.fill", title: "Analytics", description: "View costs and trends")
            }
            .padding(.horizontal)

            Spacer()

            Button {
                showingAddVehicle = true
            } label: {
                Text("Add Your First Vehicle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(showingAddVehicle: .constant(false))
}
