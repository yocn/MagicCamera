import SwiftUI
import UIKit

struct FrameOverlayView: View {
    let style: FrameStyle

    var body: some View {
        GeometryReader { proxy in
            if let assetName = style.assetName, let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}
