import SwiftUI
import UIKit

struct StickerTrayView: View {
    static let recentTabID = "recent"

    let recentAssetNames: [String]
    let onPick: (String) -> Void
    let onMagicPick: () -> Void
    let onClose: () -> Void
    @State private var selectedCategoryID: String

    init(
        recentAssetNames: [String],
        onPick: @escaping (String) -> Void,
        onMagicPick: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.recentAssetNames = recentAssetNames
        self.onPick = onPick
        self.onMagicPick = onMagicPick
        self.onClose = onClose
        // 有历史就停在最近，没有就回到第一个分类。
        _selectedCategoryID = State(initialValue: recentAssetNames.isEmpty ? "hair" : Self.recentTabID)
    }

    var body: some View {
        TrayContainer(title: "挑一个贴纸吧 ✨", closeLabel: "关闭贴纸面板", onClose: onClose) {
            Button(action: onMagicPick) {
                Label("魔法搭配", systemImage: "wand.and.stars")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.purple, in: Capsule())
            }
            .accessibilityLabel("一键魔法搭配")
        } content: {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectCategory(Self.recentTabID)
                        } label: {
                            Label("最近", systemImage: "clock.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedCategoryID == Self.recentTabID ? .white : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategoryID == Self.recentTabID ? .pink : .purple.opacity(0.1),
                                    in: Capsule()
                                )
                        }
                        .id(Self.recentTabID)

                        ForEach(StickerCategoryPager.categories) { category in
                            Button {
                                selectCategory(category.id)
                            } label: {
                                Label(category.title, systemImage: category.iconName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selectedCategoryID == category.id ? .white : .purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategoryID == category.id ? .pink : .purple.opacity(0.1),
                                        in: Capsule()
                                    )
                            }
                            .id(category.id)
                        }
                    }
                    .padding(.horizontal, StickerTrayLayout.categoryStripContentPadding)
                }
                .padding(.horizontal, StickerTrayLayout.categoryStripViewportPadding)
                .onChange(of: selectedCategoryID) { id in
                    withAnimation(.easeInOut(duration: 0.18)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }

            TabView(selection: $selectedCategoryID) {
                recentPage
                    .tag(Self.recentTabID)

                ForEach(StickerCategoryPager.categories) { category in
                    stickerPage(for: category)
                        .tag(category.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedCategoryID)
            .frame(maxHeight: .infinity)
            .padding(.horizontal, StickerTrayLayout.pagerHorizontalPadding)
        }
    }

    private func selectCategory(_ id: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedCategoryID = id
        }
    }

    private var recentPage: some View {
        // 素材可能被删或改名，查不到图的直接不显示。
        let names = recentAssetNames.filter { StickerImageProvider.image(named: $0) != nil }

        return Group {
            if names.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.purple.opacity(0.4))
                    Text("用过的贴纸会出现在这里 ✨")
                        .font(.subheadline)
                        .foregroundStyle(.purple.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                        ForEach(names, id: \.self) { name in
                            Button { onPick(name) } label: {
                                Image(uiImage: StickerImageProvider.image(named: name) ?? UIImage())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 58, height: 58)
                                    .padding(5)
                                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .pink.opacity(0.18), radius: 5, y: 2)
                            }
                            .accessibilityLabel("最近用过的贴纸：\(name)")
                        }
                    }
                }
                .padding(.horizontal, StickerTrayLayout.gridHorizontalPadding)
            }
        }
    }

    private func stickerPage(for category: StickerCategory) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                ForEach(category.assetNames, id: \.self) { name in
                    Button { onPick(name) } label: {
                        Image(uiImage: StickerImageProvider.image(named: name) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .padding(5)
                            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .pink.opacity(0.18), radius: 5, y: 2)
                    }
                    .accessibilityLabel("添加\(category.title)贴纸：\(name)")
                }
            }
        }
        .padding(.horizontal, StickerTrayLayout.gridHorizontalPadding)
    }
}
