import SwiftUI

struct GreetingHeaderView: View {
    @AppStorage("userName") private var userName = ""

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    private var displayName: String {
        userName.isEmpty ? "Driver" : userName
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(greeting)
                    .font(Theme.Typography.label)
                    .foregroundColor(.textSecondary)
                Text(displayName)
                    .font(Theme.Typography.greeting)
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryPurple, Color.pinkAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Text(displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        GreetingHeaderView()
    }
}
