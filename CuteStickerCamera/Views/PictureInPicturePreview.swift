import AVFoundation
import SwiftUI

struct PictureInPicturePreview: View {
    let previewLayer: AVCaptureVideoPreviewLayer
    @Binding var layout: PictureInPictureLayout
    let canvasSize: CGSize
    @State private var dragOrigin: PictureInPictureLayout?

    var body: some View {
        let rect = layout.rect(in: canvasSize)
        ConnectedCameraPreview(previewLayer: previewLayer)
            .frame(width: rect.width, height: rect.height)
            .clipShape(RoundedRectangle(cornerRadius: rect.width * 0.14))
            .overlay {
                RoundedRectangle(cornerRadius: rect.width * 0.14)
                    .strokeBorder(.white, lineWidth: rect.width * 0.015)
            }
            .contentShape(Rectangle())
            .position(x: rect.midX, y: rect.midY)
            .gesture(DragGesture(coordinateSpace: .named("pipCanvas"))
                .onChanged { value in
                    if dragOrigin == nil { dragOrigin = layout }
                    layout.center = dragOrigin?.normalizedCenter(afterDragging: value.translation, in: canvasSize)
                }
                .onEnded { _ in dragOrigin = nil })
            .accessibilityLabel("前摄小窗，可拖动")
    }
}
