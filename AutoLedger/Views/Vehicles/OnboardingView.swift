import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "fuelpump.fill",
            title: "Fuel Tracking",
            subtitle: "Monitor Every Fill-Up",
            description: "Log Fuel Purchases, Track Mileage,\nand See Spending Trends Over Time.",
            color: .greenAccent
        ),
        OnboardingPage(
            icon: "wrench.and.screwdriver.fill",
            title: "Maintenance",
            subtitle: "Never Miss a Service",
            description: "Schedule Oil Changes, Tire Rotations,\nand Track Your Service History.",
            color: .orange
        ),
        OnboardingPage(
            icon: "location.fill",
            title: "Trip Logging",
            subtitle: "Track Every Journey",
            description: "Log Business Trips for Tax Deductions\nand Monitor Your Driving Patterns.",
            color: .primaryPurple
        )
    ]

    var body: some View {
        ZStack {
            Color.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        onComplete()
                    }
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Color.cardBackground)
                    .cornerRadius(Theme.CornerRadius.pill)
                    .padding(.trailing, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                }

                // Swipeable pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        if index == currentPage {
                            Capsule()
                                .fill(pages[currentPage].color)
                                .frame(width: Theme.Spacing.lg, height: Theme.Spacing.sm)
                        } else {
                            Circle()
                                .fill(Color.textSecondary.opacity(0.3))
                                .frame(width: Theme.Spacing.sm, height: Theme.Spacing.sm)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: currentPage)
                .padding(.bottom, Theme.Spacing.xl)

                // CTA Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(Theme.Typography.cardTitle)

                        Image(systemName: "arrow.right")
                            .font(Theme.Typography.iconTiny)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.CornerRadius.large)
                }
                .animation(.easeInOut(duration: 0.2), value: currentPage)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            // Floating particles
            FloatingParticle(size: 4, offset: CGPoint(x: -150, y: -300), color: page.color, delay: 0)
            FloatingParticle(size: 3, offset: CGPoint(x: 120, y: -280), color: page.color, delay: 0.2)
            FloatingParticle(size: 5, offset: CGPoint(x: -80, y: -200), color: page.color, delay: 0.4)
            FloatingParticle(size: 3, offset: CGPoint(x: 160, y: -150), color: page.color, delay: 0.6)
            FloatingParticle(size: 4, offset: CGPoint(x: -140, y: -100), color: page.color, delay: 0.8)
            FloatingParticle(size: 3, offset: CGPoint(x: 100, y: -50), color: page.color, delay: 1.0)
            FloatingParticle(size: 5, offset: CGPoint(x: -160, y: 0), color: page.color, delay: 1.2)
            FloatingParticle(size: 4, offset: CGPoint(x: 140, y: 50), color: page.color, delay: 0.3)
            FloatingParticle(size: 3, offset: CGPoint(x: -100, y: 100), color: page.color, delay: 0.5)
            FloatingParticle(size: 4, offset: CGPoint(x: 170, y: 150), color: page.color, delay: 0.7)

            VStack(spacing: 0) {
                Spacer()

                // Icon - clean and bright
                Image(systemName: page.icon)
                    .font(.system(size: 100, weight: .medium))
                    .foregroundColor(page.color)
                    .frame(height: 280)

                Spacer().frame(height: Theme.Spacing.xxl)

                // Text Content
                VStack(spacing: Theme.Spacing.md) {
                    Text(page.title)
                        .font(Theme.Typography.largeTitle)
                        .foregroundColor(.textPrimary)

                    Text(page.subtitle)
                        .font(Theme.Typography.title3)
                        .foregroundColor(page.color)

                    Text(page.description)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()
            }
        }
    }
}

// MARK: - Floating Particle

struct FloatingParticle: View {
    let size: CGFloat
    let offset: CGPoint
    let color: Color
    let delay: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.6))
            .frame(width: size, height: size)
            .offset(x: offset.x, y: offset.y)
            .offset(y: isAnimating ? -8 : 8)
            .animation(
                Animation.easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
