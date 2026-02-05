import SwiftUI

struct SpeedometerGaugeView: View {
    let value: Double
    let maxValue: Double
    let title: String
    let unit: String
    var color: Color = .primaryPurple

    @State private var animatedValue: Double = 0

    private var progress: Double {
        min(animatedValue / maxValue, 1.0)
    }

    private var formattedValue: String {
        if animatedValue >= 1000 {
            return String(format: "%.1fK", animatedValue / 1000)
        }
        return String(format: "%.0f", animatedValue)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Background arc
                ArcShape(startAngle: 135, endAngle: 405)
                    .stroke(
                        Color.white.opacity(0.1),
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )

                // Progress arc
                ArcShape(startAngle: 135, endAngle: 135 + (270 * progress))
                    .stroke(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 12,
                            lineCap: .round
                        )
                    )
                    .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)

                // Tick marks
                ForEach(0..<9) { index in
                    TickMark(index: index)
                }

                // Center content
                VStack(spacing: 4) {
                    Text(formattedValue)
                        .font(Theme.Typography.statValueMedium)
                        .foregroundColor(.textPrimary)
                    Text(unit)
                        .font(Theme.Typography.label)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 160, height: 140)

            Text(title)
                .font(Theme.Typography.cardSubtitle)
                .foregroundColor(.textSecondary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
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

struct ArcShape: Shape {
    let startAngle: Double
    let endAngle: Double

    var animatableData: Double {
        get { endAngle }
        set { }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY + 10)
        let radius = min(rect.width, rect.height) / 2 - 10

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )

        return path
    }
}

struct TickMark: View {
    let index: Int

    private var angle: Double {
        135 + (Double(index) * 33.75)
    }

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 2, height: index % 2 == 0 ? 8 : 4)
            .offset(y: -55)
            .rotationEffect(.degrees(angle))
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        SpeedometerGaugeView(
            value: 45678,
            maxValue: 100000,
            title: "Odometer",
            unit: "miles",
            color: .primaryPurple
        )
    }
}
