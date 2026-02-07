import SwiftUI

struct GreetingHeaderView: View {
    @EnvironmentObject var authService: AuthenticationService

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
        let name = authService.userProfile?.name ?? ""
        return name.isEmpty ? "Driver" : name
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

            GradientAvatarView(
                uid: authService.user?.uid,
                name: authService.userProfile?.name,
                photoURL: authService.userProfile?.photoURL,
                size: 44
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        GreetingHeaderView()
            .environmentObject(AuthenticationService())
    }
}
