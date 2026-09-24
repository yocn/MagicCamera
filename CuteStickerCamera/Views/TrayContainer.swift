import SwiftUI

enum TrayLayout {
    static let headerTopPadding: CGFloat = 28
    static let horizontalPadding: CGFloat = 20
    static let contentSpacing: CGFloat = 12
}

/// 底部面板的统一外壳：居中标题、右上角关闭按钮、顶部对齐。
/// 三个面板共用，关闭一律走按钮，不支持下滑消失。
struct TrayContainer<Leading: View, Content: View>: View {
    let title: String
    let closeLabel: String
    let onClose: () -> Void
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: TrayLayout.contentSpacing) {
            header
            content()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.purple)
            HStack {
                leading()
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.pink, in: Circle())
                }
                .accessibilityLabel(closeLabel)
            }
        }
        .padding(.horizontal, TrayLayout.horizontalPadding)
        .padding(.top, TrayLayout.headerTopPadding)
    }
}

extension TrayContainer where Leading == EmptyView {
    init(
        title: String,
        closeLabel: String,
        onClose: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title: title, closeLabel: closeLabel, onClose: onClose, leading: { EmptyView() }, content: content)
    }
}
