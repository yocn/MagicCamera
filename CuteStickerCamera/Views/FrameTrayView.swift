import SwiftUI
import UIKit

struct FrameTrayView: View {
    let selected: FrameStyle
    let recentStyles: [FrameStyle]
    let onPick: (FrameStyle) -> Void
    let onClose: () -> Void
    @State private var selectedTab: FrameTrayTab

    init(
        selected: FrameStyle,
        recentStyles: [FrameStyle],
        onPick: @escaping (FrameStyle) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selected = selected
        self.recentStyles = recentStyles
        self.onPick = onPick
        self.onClose = onClose
        // 有历史就停在最近，没有就回到当前边框所在分类。
        _selectedTab = State(initialValue: recentStyles.isEmpty ? .category(selected.category) : .recent)
    }

    var body: some View {
        TrayContainer(title: "给照片换个边框吧 ✨", closeLabel: "关闭边框面板", onClose: onClose) {
            categoryTabs

            TabView(selection: $selectedTab) {
                recentPage
                    .tag(FrameTrayTab.recent)

                ForEach(FrameCategory.allCases) { category in
                    framePage(for: category)
                        .tag(FrameTrayTab.category(category))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .frame(maxHeight: .infinity)
        }
    }

    private var recentPage: some View {
        // 边框素材在增删，解析不出资源的旧记录直接不显示。
        let styles = recentStyles.filter { $0.assetName != nil }

        return Group {
            if styles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.purple.opacity(0.4))
                    Text("用过的边框会出现在这里 ✨")
                        .font(.subheadline)
                        .foregroundStyle(.purple.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                        ForEach(styles, id: \.self) { style in
                            FrameChoiceButton(style: style, isSelected: style == selected) {
                                onPick(style)
                            }
                        }
                    }
                    .padding(.horizontal, TrayLayout.horizontalPadding)
                }
            }
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
                guard selectedTab == .category(category), category == selected.category else { return }
                DispatchQueue.main.async { proxy.scrollTo(selected, anchor: .center) }
            }
        }
    }

    private var categoryTabs: some View {
        ScrollViewReader { tabProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { selectedTab = .recent }
                    } label: {
                        Label("最近", systemImage: "clock.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selectedTab == .recent ? .white : .purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                selectedTab == .recent ? Color.pink : Color.purple.opacity(0.1),
                                in: Capsule()
                            )
                    }
                    .id(FrameTrayTab.recent)
                    .accessibilityLabel("最近用过的边框")

                    ForEach(FrameCategory.allCases) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedTab = .category(category)
                            }
                        } label: {
                            Label(category.title, systemImage: category.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedTab == .category(category) ? .white : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    selectedTab == .category(category) ? Color.pink : Color.purple.opacity(0.1),
                                    in: Capsule()
                                )
                        }
                        .id(FrameTrayTab.category(category))
                        .accessibilityLabel("边框分类：\(category.title)")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear {
                DispatchQueue.main.async { tabProxy.scrollTo(selectedTab, anchor: .center) }
            }
            .onChange(of: selectedTab) { tab in
                withAnimation(.easeInOut(duration: 0.18)) { tabProxy.scrollTo(tab, anchor: .center) }
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
            // strokeBorder 在内侧描边；stroke 会有一半线宽长在 frame 外，被网格裁掉。
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(borderColor, lineWidth: isSelected ? 4 : 2)
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

enum FrameTrayTab: Hashable {
    case recent
    case category(FrameCategory)
}
