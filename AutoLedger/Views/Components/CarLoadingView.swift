import SwiftUI

/// Animated muscle car silhouette with a shimmer gradient sweep — used as the app's loading indicator.
struct CarLoadingView: View {
    var size: CGFloat = 44
    @State private var phase: CGFloat = 0

    private var carImage: some View {
        Image("CarSilhouette")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size)
    }

    var body: some View {
        // Single wide gradient that slides through the car mask
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.3),
                .init(color: .primaryPurple, location: 0.45),
                .init(color: .purpleGradientEnd, location: 0.55),
                .init(color: .white, location: 0.7),
                .init(color: .white, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .scaleEffect(x: 3, anchor: .leading)
        .offset(x: phase)
        .mask { carImage }
        .aspectRatio(400 / 113, contentMode: .fit)
        .frame(height: size)
        .onAppear {
            // Use a timer-driven animation for smooth looping
            phase = 0
            withAnimation(
                .linear(duration: 2.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = -size * (400 / 113) * 2
            }
        }
    }
}

/// Full-screen loading overlay with animated car and optional message.
struct CarLoadingOverlay: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                CarLoadingView(size: 36)
                if let message {
                    Text(message)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            CarLoadingView()
            CarLoadingView(size: 52)
            CarLoadingOverlay(message: "Please Wait...")
        }
    }
}
