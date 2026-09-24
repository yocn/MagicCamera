import SwiftUI

struct DoodleToolbar: View {
    @Binding var tool: DoodleToolState
    let onUndo: () -> Void
    let onClear: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            colorRow
            actionRow
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
    }

    private var colorRow: some View {
        HStack(spacing: 6) {
            ForEach(DoodlePalette.all) { item in
                Button {
                    tool.color = item
                    tool.isErasing = false
                } label: {
                    Circle()
                        .fill(Color(red: item.red, green: item.green, blue: item.blue))
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(.white, lineWidth: isPicked(item) ? 3 : 1))
                        .scaleEffect(isPicked(item) ? 1.18 : 1)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .frame(width: 38, height: 38)
                        .contentShape(Circle())
                }
                .accessibilityLabel("画笔颜色：\(item.title)")
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            ForEach(DoodleBrushWidth.allCases) { item in
                Button {
                    tool.width = item
                    tool.isErasing = false
                } label: {
                    Circle()
                        .fill(tool.width == item && !tool.isErasing ? Color.pink : Color.white.opacity(0.85))
                        .frame(width: item.pointSize * 0.7 + 8, height: item.pointSize * 0.7 + 8)
                        .frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .accessibilityLabel("画笔粗细：\(item.title)")
            }

            actionButton(systemImage: "eraser.fill", isActive: tool.isErasing) {
                tool.isErasing.toggle()
            }
            .accessibilityLabel(tool.isErasing ? "切回画笔" : "使用橡皮")

            actionButton(systemImage: "arrow.uturn.backward", isActive: false, action: onUndo)
                .accessibilityLabel("撤销一笔")

            actionButton(systemImage: "trash.fill", isActive: false, action: onClear)
                .accessibilityLabel("清空涂鸦")

            Button(action: onDone) {
                Text("完成")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.pink, in: Capsule())
            }
            .accessibilityLabel("退出涂鸦")
        }
    }

    private func actionButton(systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? .white : .purple)
                .frame(width: 40, height: 40)
                .background(isActive ? Color.pink : Color.white.opacity(0.85), in: Circle())
        }
    }

    private func isPicked(_ item: DoodleColor) -> Bool {
        tool.color == item && !tool.isErasing
    }
}
