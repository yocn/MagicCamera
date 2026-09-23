import SwiftUI

/// 按排版摆放格子，每格内容由调用方提供。
struct CollageGridView<Content: View>: View {
    let layout: CollageLayout
    let spacing: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(layout.cells.enumerated()), id: \.offset) { index, cell in
                content(index)
                    .frame(
                        width: max(0, cell.width * proxy.size.width - spacing),
                        height: max(0, cell.height * proxy.size.height - spacing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .position(
                        x: cell.midX * proxy.size.width,
                        y: cell.midY * proxy.size.height
                    )
            }
        }
        .aspectRatio(layout.aspectRatio, contentMode: .fit)
    }
}
