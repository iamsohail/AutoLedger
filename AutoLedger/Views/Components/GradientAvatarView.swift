import SwiftUI

struct GradientAvatarView: View {
    let uid: String?
    let name: String?
    let photoURL: String?
    var size: CGFloat = 44

    private static let palettes: [(Color, Color)] = [
        (Color(hex: "FF6B6B"), Color(hex: "FFB347")),  // Sunset
        (Color(hex: "A18CD1"), Color(hex: "FBC2EB")),  // Aurora
        (Color(hex: "667EEA"), Color(hex: "764BA2")),  // Ocean
        (Color(hex: "11998E"), Color(hex: "38EF7D")),  // Emerald
        (Color(hex: "F7971E"), Color(hex: "FFD200")),  // Fire
        (Color(hex: "ED4264"), Color(hex: "FFEDBC")),  // Berry
        (Color(hex: "FF9A9E"), Color(hex: "FECFEF")),  // Coral
        (Color(hex: "4FACFE"), Color(hex: "00F2FE")),  // Electric
        (Color(hex: "F093FB"), Color(hex: "F5576C")),  // Mango
        (Color(hex: "43E97B"), Color(hex: "38F9D7")),  // Forest
        (Color(hex: "FA709A"), Color(hex: "FEE140")),  // Twilight
        (Color(hex: "30CFD0"), Color(hex: "330867")),  // Cobalt
    ]

    private static let directions: [(UnitPoint, UnitPoint)] = [
        (.topLeading, .bottomTrailing),
        (.top, .bottom),
        (.topTrailing, .bottomLeading),
        (.leading, .trailing),
    ]

    private var hash: Int {
        stableHash(for: uid ?? "default")
    }

    private var palette: (Color, Color) {
        let index = abs(hash) % Self.palettes.count
        return Self.palettes[index]
    }

    private var direction: (UnitPoint, UnitPoint) {
        let index = abs(hash / Self.palettes.count) % Self.directions.count
        return Self.directions[index]
    }

    private var initial: String? {
        guard let name, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.0, palette.1],
                        startPoint: direction.0,
                        endPoint: direction.1
                    )
                )
                .frame(width: size, height: size)

            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    overlayContent
                }
                .frame(width: size - 4, height: size - 4)
                .clipShape(Circle())
            } else {
                overlayContent
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let initial {
            Text(initial)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
        }
    }

    private func stableHash(for string: String) -> Int {
        // djb2 hash — deterministic across launches
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(byte)
        }
        return Int(hash & 0x7FFFFFFFFFFFFFFF)
    }
}

#Preview {
    ZStack {
        Color.darkBackground.ignoresSafeArea()
        HStack(spacing: 16) {
            GradientAvatarView(uid: "abc123", name: "Sohail", photoURL: nil, size: 60)
            GradientAvatarView(uid: "xyz789", name: nil, photoURL: nil, size: 60)
            GradientAvatarView(uid: "test456", name: "Ali", photoURL: nil, size: 40)
        }
    }
}
