import SwiftUI

struct PhotoFilterBar: View {
    @Binding var filter: PhotoFilter
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PhotoFilter.allCases) { item in
                        Button { filter = item } label: {
                            VStack(spacing: 5) {
                                Image(systemName: item.iconName)
                                    .font(.headline)
                                    .foregroundStyle(filter == item ? .white : .purple)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        filter == item ? Color.pink : Color.white.opacity(0.85),
                                        in: Circle()
                                    )
                                Text(item.title)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(filter == item ? .pink : .purple)
                            }
                        }
                        .accessibilityLabel("滤镜：\(item.title)")
                    }
                }
                .padding(.horizontal, 4)
            }

            Button(action: onDone) {
                Text("完成")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.pink, in: Capsule())
            }
            .accessibilityLabel("收起滤镜")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
    }
}
