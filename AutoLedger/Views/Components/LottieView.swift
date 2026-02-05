import SwiftUI
import Lottie

/// A SwiftUI view that displays a Lottie animation
struct LottieView: View {
    let name: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat

    init(
        name: String,
        loopMode: LottieLoopMode = .loop,
        animationSpeed: CGFloat = 1.0
    ) {
        self.name = name
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
    }

    var body: some View {
        LottieViewRepresentable(
            name: name,
            loopMode: loopMode,
            animationSpeed: animationSpeed
        )
    }
}

/// UIViewRepresentable wrapper for LottieAnimationView
struct LottieViewRepresentable: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // No updates needed
    }
}

#Preview {
    LottieView(name: "fuel-animation")
        .frame(width: 100, height: 100)
}
