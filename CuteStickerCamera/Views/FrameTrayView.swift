import SwiftUI
import UIKit

struct FrameTrayView: View {
    let selected: FrameStyle
    let onPick: (FrameStyle) -> Void
    let onClose: () -> Void
    @State private var selectedCategory: FrameCategory

    init(selected: FrameStyle, onPick: @escaping (FrameStyle) -> Void, onClose: @escaping () -> Void) {
        self.selected = selected
        self.onPick = onPick
        self.onClose = onClose
        _selectedCategory = State(initialValue: selected.category)
    }

    var body: some View {
        TrayContainer(title: "给照片换个边框吧 ✨", closeLabel: "关闭边框面板", onClose: onClose) {
            categoryTabs

            TabView(selection: $selectedCategory) {
                ForEach(FrameCategory.allCases) { category in
                    framePage(for: category)
                        .tag(category)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedCategory)
            .frame(maxHeight: .infinity)
        }
    }

    private func framePage(for category: FrameCategory) -> some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                    ForEach(category.styles, id: \.self) { style in
                        FrameChoiceButton(style: style, isSelected: style == selected) {
                            onPick(style)
                        }
                        .id(style)
                    }
                }
                .padding(.horizontal, TrayLayout.horizontalPadding)
            }
            // 打开面板时直接停在当前选中的边框上，不用自己翻。
            .onAppear {
                guard category == selected.category else { return }
                DispatchQueue.main.async { proxy.scrollTo(selected, anchor: .center) }
            }
        }
    }

    private var categoryTabs: some View {
        ScrollViewReader { tabProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FrameCategory.allCases) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedCategory = category
                            }
                        } label: {
                            Label(category.title, systemImage: category.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedCategory == category ? .white : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedCategory == category ? Color.pink : Color.purple.opacity(0.1),
                                    in: Capsule()
                                )
                        }
                        .id(category)
                        .accessibilityLabel("边框分类：\(category.title)")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                DispatchQueue.main.async { tabProxy.scrollTo(selectedCategory, anchor: .center) }
            }
            .onChange(of: selectedCategory) { category in
                withAnimation(.easeInOut(duration: 0.18)) { tabProxy.scrollTo(category, anchor: .center) }
            }
        }
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
                    .scaledToFit()
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
