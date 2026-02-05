import SwiftUI

struct CircularGaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    var color: Color = .primaryPurple
    var size: CGFloat = 120

    @State private var animatedValue: Double = 0

    private var progress: Double {
        min(animatedValue / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.white.opacity(0.1),
                        lineWidth: 10
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 10,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)

                // Value text
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", animatedValue))
                        .font(Theme.Typography.statValueSmall)
                        .foregroundColor(.textPrimary)
                    Text(unit)
                        .font(Theme.Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: size, height: size)

            Text(title)
                .font(Theme.Typography.label)
                .foregroundColor(.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedValue = newValue
            }
        }
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        HStack(spacing: 32) {
            CircularGaugeView(
                value: 15.5,
                maxValue: 25,
                title: "Avg Mileage",
                unit: "km/l",
                color: .greenAccent
            )
            CircularGaugeView(
                value: 156,
                maxValue: 200,
                title: "Distance",
                unit: "mi",
                color: .pinkAccent
            )
        }
    }
}
