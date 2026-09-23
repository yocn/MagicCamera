import SwiftUI
import UIKit

/// 大头贴模式下的可拖动浮层：显示当前排版与花边，拍摄中逐格填入照片。
struct CollageProgressView: View {
    let session: CollageSession
    let thumbnails: [UIImage]
    let isCapturing: Bool
    @Binding var overlayLayout: CollageOverlayLayout
    let canvasSize: CGSize
    let onClose: () -> Void

    @State private var dragOrigin: CollageOverlayLayout?

    private static let renderWidth: CGFloat = 360
    // 预览按 body 同步取用，靠缓存避免拖动时反复合成。
    private static let cache = NSCache<NSString, UIImage>()

    var body: some View {
        let rect = overlayLayout.rect(in: canvasSize, aspectRatio: session.layout.aspectRatio)

        ZStack {
            Image(uiImage: preview)
                .resizable()
                .frame(width: rect.width, height: rect.height)
                .overlay(alignment: .bottom) { modeBadge.padding(.bottom, 5) }
                .shadow(color: .black.opacity(0.28), radius: 6, y: 2)
                .contentShape(Rectangle())
                .position(x: rect.midX, y: rect.midY)
                .gesture(dragGesture)
                .accessibilityLabel("大头贴预览，可拖动，已拍 \(thumbnails.count) 张，共 \(session.layout.shotCount) 张")

            // 独立一层并悬在角外：既不挡预览，点击也不会被拖动手势吞掉。
            closeButton
                .position(x: rect.maxX, y: rect.minY)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .named("collageCanvas"))
            .onChanged { value in
                if dragOrigin == nil { dragOrigin = overlayLayout }
                overlayLayout.center = dragOrigin?.normalizedCenter(
                    afterDragging: value.translation,
                    in: canvasSize,
                    aspectRatio: session.layout.aspectRatio
                )
            }
            .onEnded { _ in dragOrigin = nil }
    }

    private var preview: UIImage {
        let highlight = isCapturing ? session.currentIndex : nil
        let key = "\(session.id)-\(thumbnails.count)-\(highlight.map(String.init) ?? "none")" as NSString
        if let cached = Self.cache.object(forKey: key) { return cached }

        let image = CollageComposer().preview(
            shots: thumbnails,
            layout: session.layout,
            style: session.style,
            width: Self.renderWidth,
            highlightIndex: highlight
        )
        Self.cache.setObject(image, forKey: key)
        return image
    }

    private var modeBadge: some View {
        Text(session.mode.badgeTitle)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.black.opacity(0.55), in: Capsule())
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(.black.opacity(0.62), in: Circle())
        }
        .accessibilityLabel("关闭大头贴模式")
    }
}
