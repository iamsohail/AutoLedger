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

                if let photoURL = authService.userProfile?.photoURL,
                   let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(displayName.prefix(1).uppercased())
                            .font(Theme.Typography.cardTitle)
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Text(displayName.prefix(1).uppercased())
                        .font(Theme.Typography.cardTitle)
                        .foregroundColor(.white)
                }
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
            .environmentObject(AuthenticationService())
    }
}
