import SwiftUI

/// iOS 26 起相机控件用 Liquid Glass，更早的系统退回原来的半透明黑底。
extension View {
    func glassCircleControl(isActive: Bool = false) -> some View {
        modifier(GlassControlBackground(shape: Circle(), isActive: isActive))
    }

    func glassCapsuleControl(isActive: Bool = false) -> some View {
        modifier(GlassControlBackground(shape: Capsule(), isActive: isActive))
    }
}

private struct GlassControlBackground<S: Shape>: ViewModifier {
    let shape: S
    let isActive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
            content.background(fallbackFill, in: shape)
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        isActive ? .regular.tint(.pink).interactive() : .regular.interactive()
    }

    private var fallbackFill: Color {
        isActive ? .pink.opacity(0.9) : .black.opacity(0.3)
    }
}
