import SwiftUI

struct CollageTrayView: View {
    @Binding var layout: CollageLayout
    @Binding var style: CollageStyle
    @Binding var mode: CollageCaptureMode
    /// 任何一次选择都算开启大头贴模式，点回当前项也算。
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        TrayContainer(title: "大头贴 ✨", closeLabel: "关闭大头贴面板", onClose: onClose) {
            layoutRow
            styleRow
            modeRow
            startButton
        }
    }

    private var layoutRow: some View {
        row(title: "排版") {
            ForEach(CollageLayout.allCases) { item in
                Button {
                    layout = item
                    onSelect()
                } label: {
                    VStack(spacing: 6) {
                        CollageGridView(layout: item, spacing: 1.5, cornerRadius: 2) { _ in
                            Rectangle().fill(layout == item ? Color.white : Color.purple.opacity(0.45))
                        }
                        .frame(width: 38, height: 42)
                        Text(item.title).font(.caption2.weight(.medium))
                    }
                    .padding(.vertical, 8)
                    .frame(width: 74)
                    .background(
                        layout == item ? Color.pink : Color.purple.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(layout == item ? .white : .purple)
                }
                .accessibilityLabel("排版：\(item.title)")
            }
        }
    }

    private var styleRow: some View {
        row(title: "花边") {
            ForEach(CollageStyle.allCases) { item in
                Button {
                    style = item
                    onSelect()
                } label: {
                    Label(item.title, systemImage: item.iconName)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            style == item ? Color.pink : Color.purple.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(style == item ? .white : .purple)
                }
                .accessibilityLabel("花边：\(item.title)")
            }
        }
    }

    private var modeRow: some View {
        row(title: "拍法") {
            ForEach(CollageCaptureMode.allCases) { item in
                Button {
                    mode = item
                    onSelect()
                } label: {
                    Label(item.title, systemImage: item.iconName)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            mode == item ? Color.pink : Color.purple.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(mode == item ? .white : .purple)
                }
                .accessibilityLabel("拍法：\(item.title)")
            }
        }
    }

    private var startButton: some View {
        Button(action: onClose) {
            Text("确定")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(.pink, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, StickerTrayLayout.gridHorizontalPadding)
        .padding(.top, 4)
        .accessibilityLabel("确定并关闭面板")
    }

    private func row<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple.opacity(0.7))
                .padding(.horizontal, StickerTrayLayout.headerHorizontalPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.horizontal, StickerTrayLayout.categoryStripContentPadding)
            }
        }
    }
}
