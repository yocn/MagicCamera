import SwiftUI
import UIKit

struct StickerTrayView: View {
    let onPick: (String) -> Void

    private let stickers = [
        "bunny", "kitten", "puppy", "panda",
        "rainbow", "shooting_star", "sun", "heart",
        "strawberry", "cupcake", "crown", "flower",
        "balloon", "dinosaur", "cloud", "sparkle"
    ]

    var body: some View {
        VStack(spacing: 10) {
            Capsule().fill(.secondary.opacity(0.4)).frame(width: 38, height: 5)
            Text("挑一个贴纸吧 ✨")
                .font(.headline)
                .foregroundStyle(.purple)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                ForEach(stickers, id: \.self) { name in
                    Button { onPick(name) } label: {
                        Image(uiImage: UIImage(named: name) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .padding(5)
                            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .pink.opacity(0.18), radius: 5, y: 2)
                    }
                    .accessibilityLabel("添加 \(name) 贴纸")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(.ultraThinMaterial)
    }
}
