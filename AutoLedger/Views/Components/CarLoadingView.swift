import SwiftUI

/// Animated car icon with pulsing purple glow — used as the app's loading indicator.
struct CarLoadingView: View {
    var size: CGFloat = 44
    @State private var isGlowing = false
    @State private var isFloating = false

    var body: some View {
        Image(systemName: "car.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [.primaryPurple, .purpleGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .primaryPurple.opacity(isGlowing ? 0.8 : 0.2), radius: isGlowing ? 20 : 8)
            .shadow(color: .primaryPurple.opacity(isGlowing ? 0.4 : 0.1), radius: isGlowing ? 40 : 16)
            .offset(y: isFloating ? -4 : 4)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isGlowing
            )
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isGlowing = true
                isFloating = true
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
            CarLoadingView(size: 28)
            CarLoadingOverlay(message: "Please Wait...")
        }
    }
}
