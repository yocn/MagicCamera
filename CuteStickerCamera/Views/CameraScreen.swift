import SwiftUI
import UIKit

struct CameraScreen: View {
    @StateObject private var camera = CameraService()
    @StateObject private var canvas = StickerCanvas()
    @State private var isStickerTrayPresented = false
    @State private var isFrameTrayPresented = false
    @State private var frameStyle: FrameStyle = .none
    @State private var saveTracker = PhotoSaveTracker()
    @State private var message: String?
    @AppStorage(CameraSoundPreference.storageKey) private var isCameraSoundEnabled = true
    @State private var isShutterFlashVisible = false
    private let composer = PhotoComposer()
    private let photoLibrarySaver = PhotoLibrarySaver()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()

                if camera.permissionState != .ready {
                    permissionOverlay
                        .allowsHitTesting(camera.permissionState.allowsPermissionOverlayInteraction)
                }

                StickerCanvasView(canvas: canvas, previewSize: proxy.size)
                    .ignoresSafeArea()
                    .allowsHitTesting(camera.permissionState.allowsStickerEditing)

                FrameOverlayView(style: frameStyle)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Color.black
                    .opacity(isShutterFlashVisible ? 1 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.18), value: isShutterFlashVisible)

                VStack {
                    if CameraScreenChrome.showsAppTitle {
                        title
                    }
                    Spacer()
                    controls
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)

                if let message {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .padding(.bottom, 130)
                    }
                }

            }
            .sheet(isPresented: $isStickerTrayPresented) {
                StickerTrayView { name in
                    canvas.add(assetName: name)
                    isStickerTrayPresented = false
                }
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isFrameTrayPresented) {
                FrameTrayView(selected: frameStyle) { style in
                    frameStyle = style
                    isFrameTrayPresented = false
                }
                .presentationDetents([.height(210)])
                .presentationDragIndicator(.hidden)
            }
            .onAppear { camera.start() }
            .onDisappear { camera.stop() }
            .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
                saveComposed(image, previewSize: proxy.size, frameStyle: frameStyle)
            }
        }
    }

    private var title: some View {
        Text("✨ 贴纸相机")
            .font(.title3.weight(.bold))
            .foregroundStyle(.white)
            .shadow(radius: 4)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(.pink.opacity(0.7), in: Capsule())
    }

    private var controls: some View {
        HStack(alignment: .center) {
            Button(action: openSystemPhotos) {
                Image(systemName: "photo.on.rectangle.angled")
            }
            .accessibilityLabel("打开系统照片")

            Spacer()

            Button(action: capturePhoto) {
                ZStack {
                    Circle().fill(.white).frame(width: 74, height: 74)
                    Circle().stroke(.pink, lineWidth: 6).frame(width: 64, height: 64)
                    if camera.isCapturing { ProgressView().tint(.pink) }
                }
            }
            .disabled(camera.isCapturing || camera.permissionState != .ready)
            .buttonStyle(ShutterButtonStyle())
            .accessibilityLabel("拍照")

            Spacer()

            VStack(spacing: 12) {
                Button { camera.switchCamera() } label: { Image(systemName: "camera.rotate.fill") }
                    .accessibilityLabel("切换镜头")
                Button { isStickerTrayPresented = true } label: { Text("🐰").font(.title2) }
                    .accessibilityLabel("添加贴纸")
                Button { isFrameTrayPresented = true } label: { Image(systemName: "rectangle.inset.filled") }
                    .accessibilityLabel("选择边框")
                Button { isCameraSoundEnabled.toggle() } label: {
                    Image(systemName: isCameraSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
                    .accessibilityLabel(isCameraSoundEnabled ? "拍照音效已开启" : "拍照音效已关闭")
                Button { canvas.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .accessibilityLabel("撤销")
            }
        }
        .font(.title2)
        .foregroundStyle(.white)
        .padding(.bottom, 18)
        .shadow(radius: 4)
    }

    private var permissionOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill").font(.largeTitle).foregroundStyle(.pink)
            Text(camera.permissionState.message ?? "相机暂不可用")
                .multilineTextAlignment(.center)
            if camera.permissionState == .cameraDenied {
                Button("前往设置") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
        .padding(28)
    }

    private func saveComposed(_ image: UIImage, previewSize: CGSize, frameStyle: FrameStyle) {
        saveTracker.beginSave()
        let layers = canvas.layers
        Task.detached(priority: .userInitiated) {
            do {
                let result = try PhotoComposer().compose(image: image, previewSize: previewSize, layers: layers, frameStyle: frameStyle)
                try await PhotoLibrarySaver().save(result)
                await MainActor.run {
                    saveTracker.finishSave()
                    message = "拍好啦！已经保存到系统照片 ✨"
                }
            } catch {
                await MainActor.run {
                    saveTracker.finishSave()
                    message = error.localizedDescription
                }
            }
        }
    }

    private func capturePhoto() {
        isShutterFlashVisible = true
        if isCameraSoundEnabled {
            CameraShutterEffect.playSound()
        }
        camera.capturePhoto()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            isShutterFlashVisible = false
        }
    }

    private func openSystemPhotos() {
        guard let url = URL(string: "photos-redirect://") else { return }
        UIApplication.shared.open(url) { success in
            if !success { message = "照片已保存，请打开“照片”App 继续编辑。" }
        }
    }
}

private struct ShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.58), value: configuration.isPressed)
    }
}
