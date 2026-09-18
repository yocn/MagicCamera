import SwiftUI
import UIKit

struct StickerTrayView: View {
    let onPick: (String) -> Void
    let onClose: () -> Void
    @State private var selectedCategoryID = "hair"

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .trailing) {
                Text("挑一个贴纸吧 ✨")
                    .font(.headline)
                    .foregroundStyle(.purple)
                    .frame(maxWidth: .infinity)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.pink, in: Circle())
                }
                .accessibilityLabel("关闭贴纸面板")
            }
            .padding(.horizontal, StickerTrayLayout.headerHorizontalPadding)
            .padding(.top, StickerTrayLayout.headerTopPadding)
            .padding(.bottom, StickerTrayLayout.headerBottomPadding)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
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
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    private func selectCategory(_ id: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedCategoryID = id
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
