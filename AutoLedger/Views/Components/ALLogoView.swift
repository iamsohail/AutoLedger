import SwiftUI

struct ALLogoView: View {
    var size: CGFloat = 40
    var color: Color = .white

    var body: some View {
        Image("ALMonogram")
            .resizable()
            .scaledToFit()
            .frame(height: size)
            .foregroundColor(color)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 32) {
            ALLogoView(size: 80, color: .white)
            ALLogoView(size: 60, color: .white)
        }
    }
}
