import SwiftUI
import UIKit

struct CameraScreen: View {
    @StateObject private var camera = CameraService()
    @StateObject private var canvas = StickerCanvas()
    @State private var isStickerTrayPresented = false
    @State private var isFrameTrayPresented = false
    @State private var frameStyle: FrameStyle = .none
    @State private var aspectRatio: CameraAspectRatio = .fullScreen
    @State private var saveTracker = PhotoSaveTracker()
    @State private var message: String?
    @AppStorage(CameraSoundPreference.storageKey) private var isCameraSoundEnabled = true
    @State private var isShutterFlashVisible = false
    private let composer = PhotoComposer()
    private let photoLibrarySaver = PhotoLibrarySaver()

    var body: some View {
        GeometryReader { proxy in
            let contentRect = aspectRatio.contentRect(in: proxy.size)
            ZStack {
                CameraPreview(session: camera.session)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .clipped()

                if camera.permissionState != .ready {
                    permissionOverlay
                        .allowsHitTesting(camera.permissionState.allowsPermissionOverlayInteraction)
                }

                StickerCanvasView(canvas: canvas, previewSize: contentRect.size)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .allowsHitTesting(camera.permissionState.allowsStickerEditing)

                FrameOverlayView(style: frameStyle)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
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
                    HStack {
                        Spacer()
                        settingsMenu
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
                saveComposed(image, previewSize: contentRect.size, frameStyle: frameStyle)
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
                ForEach(CameraControlGrouping.quickActions) { action in
                    quickActionButton(for: action)
                }
            }
        }
        .font(.title2)
        .foregroundStyle(.white)
        .padding(.bottom, 18)
        .shadow(radius: 4)
    }

    private var settingsMenu: some View {
        Menu {
            ForEach(CameraControlGrouping.settingsActions) { action in
                settingsMenuItem(for: action)
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .accessibilityLabel("相机设置")
    }

    @ViewBuilder
    private func quickActionButton(for action: CameraControlAction) -> some View {
        switch action {
        case .stickers:
            Button { isStickerTrayPresented = true } label: { Text("🐰").font(.title2) }
                .accessibilityLabel("添加贴纸")
        case .frames:
            Button { isFrameTrayPresented = true } label: { Image(systemName: "rectangle.inset.filled") }
                .accessibilityLabel("选择边框")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func settingsMenuItem(for action: CameraControlAction) -> some View {
        switch action {
        case .switchCamera:
            Button { camera.switchCamera() } label: { Label("切换镜头", systemImage: "camera.rotate.fill") }
        case .aspectRatio:
            Menu {
                ForEach(CameraAspectRatio.allCases) { ratio in
                    Button(ratio.title) { aspectRatio = ratio }
                }
            } label: {
                Label("拍照尺寸：\(aspectRatio.title)", systemImage: aspectRatio.iconName)
            }
        case .sound:
            Button { isCameraSoundEnabled.toggle() } label: {
                Label(
                    isCameraSoundEnabled ? "关闭拍照音效" : "开启拍照音效",
                    systemImage: isCameraSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                )
            }
        default:
            EmptyView()
        }
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
