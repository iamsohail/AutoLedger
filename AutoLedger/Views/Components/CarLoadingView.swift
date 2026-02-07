import SwiftUI

/// Gradient spinning arc — used as the app's loading indicator.
struct GradientSpinner: View {
    var size: CGFloat = 44
    var lineWidth: CGFloat? = nil
    @State private var rotation: Double = 0

    private var resolvedLineWidth: CGFloat {
        lineWidth ?? max(size * 0.14, 4)
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [.primaryPurple, .pinkAccent, .primaryPurple.opacity(0)],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: resolvedLineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

/// Full-screen loading overlay with gradient spinner and optional message.
struct CarLoadingOverlay: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                GradientSpinner(size: 40)
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
            GradientSpinner()
            GradientSpinner(size: 52)
            CarLoadingOverlay(message: "Please Wait...")
        }
    }
}
