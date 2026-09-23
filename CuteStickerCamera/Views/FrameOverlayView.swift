import SwiftUI
import UIKit

struct FrameOverlayView: View {
    let style: FrameStyle

    var body: some View {
        GeometryReader { proxy in
            if let image = FrameRenderer.image(for: style, size: proxy.size) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}
