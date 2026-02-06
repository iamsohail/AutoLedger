import SwiftUI

struct SummaryStatView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
