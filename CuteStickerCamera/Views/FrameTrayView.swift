import SwiftUI
import UIKit

struct FrameTrayView: View {
    let selected: FrameStyle
    let onPick: (FrameStyle) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(.secondary.opacity(0.4)).frame(width: 38, height: 5)
            Text("给照片换个边框吧 ✨")
                .font(.headline)
                .foregroundStyle(.purple)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FrameStyle.allCases, id: \.self) { style in
                        FrameChoiceButton(style: style, isSelected: style == selected) {
                            onPick(style)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .background(.ultraThinMaterial)
    }
}

private struct FrameChoiceButton: View {
    let style: FrameStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                iconPreview
                Text(style.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
            }
        }
        .accessibilityLabel("选择\(style.title)边框")
    }

    private var iconPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: isSelected ? 4 : 2)
                .frame(width: 54, height: 66)
            if let assetName = style.assetName, let image = UIImage(named: assetName) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 48, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            } else {
                Image(systemName: style.icon)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var borderColor: Color {
        isSelected ? .pink : .purple.opacity(0.35)
    }
}
