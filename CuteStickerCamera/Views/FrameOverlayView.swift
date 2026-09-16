import SwiftUI

struct FrameOverlayView: View {
    let style: FrameStyle

    var body: some View {
        GeometryReader { proxy in
            switch style {
            case .none:
                EmptyView()
            case .heart:
                heartFrame(in: proxy.size)
            case .rainbow:
                rainbowFrame(in: proxy.size)
            case .flower:
                flowerFrame(in: proxy.size)
            case .stars:
                starFrame(in: proxy.size)
            }
        }
    }

    private func heartFrame(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34)
                .stroke(.pink.opacity(0.9), lineWidth: 18)
                .padding(18)
            cornerDecorations(["💗", "🩷", "💞", "💖"], in: size)
        }
    }

    private func rainbowFrame(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(
                    LinearGradient(
                        colors: [.pink, .orange, .yellow, .mint, .cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 18
                )
                .padding(18)
            Text("☁️  🌈  ☁️")
                .font(.system(size: 30))
                .position(x: size.width / 2, y: 43)
            Text("✨")
                .font(.system(size: 24))
                .position(x: 48, y: size.height - 46)
            Text("✨")
                .font(.system(size: 24))
                .position(x: size.width - 48, y: size.height - 46)
        }
    }

    private func flowerFrame(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(.yellow.opacity(0.95), lineWidth: 16)
                .overlay {
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(.pink.opacity(0.72), lineWidth: 5)
                        .padding(10)
                }
                .padding(18)
            cornerDecorations(["🌸", "🌼", "🌷", "🌺"], in: size)
        }
    }

    private func starFrame(in size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(.purple.opacity(0.88), lineWidth: 18)
                .padding(18)
            cornerDecorations(["🌟", "⭐️", "💫", "✨"], in: size)
            Text("⋆｡°✩")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .purple, radius: 4)
                .position(x: size.width / 2, y: 45)
        }
    }

    private func cornerDecorations(_ symbols: [String], in size: CGSize) -> some View {
        ZStack {
            Text(symbols[0]).font(.system(size: 34)).position(x: 45, y: 45)
            Text(symbols[1]).font(.system(size: 34)).position(x: size.width - 45, y: 45)
            Text(symbols[2]).font(.system(size: 34)).position(x: 45, y: size.height - 45)
            Text(symbols[3]).font(.system(size: 34)).position(x: size.width - 45, y: size.height - 45)
        }
    }
}
