import PencilKit
import SwiftUI

struct DoodleCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: DoodleToolState
    let isActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        // 默认策略会拒绝手指输入，iPhone 上必须显式放开。
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        canvas.tool = tool.pkTool
        canvas.isUserInteractionEnabled = isActive
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DoodleCanvasView

        init(_ parent: DoodleCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

extension DoodleToolState {
    var uiColor: UIColor {
        UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
    }

    var pkTool: PKTool {
        guard isErasing else {
            return PKInkingTool(.pen, color: uiColor, width: width.pointSize)
        }
        // 带宽度的橡皮要 iOS 16.4，更早的系统只能用默认粗细。
        if #available(iOS 16.4, *) {
            return PKEraserTool(.bitmap, width: width.pointSize * 1.6)
        }
        return PKEraserTool(.bitmap)
    }
}
