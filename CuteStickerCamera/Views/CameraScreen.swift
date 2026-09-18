import SwiftUI
import UIKit

struct CameraScreen: View {
    @Environment(\.scenePhase) private var scenePhase
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
    @State private var pictureInPictureLayout = PictureInPictureLayout()
    @State private var shutterLayout = PictureInPictureLayout()
    @State private var isSettingsExpanded = false
    private let composer = PhotoComposer()
    private let photoLibrarySaver = PhotoLibrarySaver()

    var body: some View {
        GeometryReader { proxy in
            let contentRect = aspectRatio.contentRect(in: proxy.size)
            ZStack {
                Group {
                    if let dual = camera.dualCamera {
                        ConnectedCameraPreview(previewLayer: dual.rearPreview)
                            .id(ObjectIdentifier(dual))
                    } else {
                        CameraPreview(session: camera.session)
                    }
                }
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .clipped()

                if camera.permissionState != .ready {
                    permissionOverlay
                        .allowsHitTesting(camera.permissionState.allowsPermissionOverlayInteraction)
                }

                if let dual = camera.dualCamera {
                    PictureInPicturePreview(previewLayer: dual.frontPreview, layout: $pictureInPictureLayout, canvasSize: contentRect.size)
                        .id(ObjectIdentifier(dual))
                        .frame(width: contentRect.width, height: contentRect.height)
                        .coordinateSpace(name: "pipCanvas")
                        .position(x: contentRect.midX, y: contentRect.midY)
                        .allowsHitTesting(!camera.isCapturing)
                }

                StickerCanvasView(canvas: canvas, previewSize: contentRect.size,
                                  passthroughRect: camera.isPictureInPictureEnabled ? pictureInPictureLayout.rect(in: contentRect.size) : .null)
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
                        settingsControl
                    }
                    Spacer()
                    controls
                }
                .padding(.horizontal, 24)
                .padding(.top, CameraScreenChrome.topPadding(safeAreaTop: proxy.safeAreaInsets.top))
                .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 12))

                sideQuickActions(bottomInset: proxy.safeAreaInsets.bottom)

                if let displayMessage = camera.cameraMessage?.text ?? message {
                    VStack {
                        Spacer()
                        Text(displayMessage)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .padding(.bottom, 130)
                    }
                }

            }
            .ignoresSafeArea()
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
            .onChange(of: scenePhase) { phase in
                if phase == .active { camera.start() }
                if phase == .background { camera.stop() }
            }
            .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
                saveComposed(image, previewSize: contentRect.size, frameStyle: frameStyle)
            }
        }
        .ignoresSafeArea()
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
            controlButton(systemImage: "photo.on.rectangle.angled", action: openSystemPhotos)
                .accessibilityLabel("打开系统照片")

            Spacer()

            Button(action: capturePhoto) {
                ZStack {
                    Circle().fill(.white).frame(width: 74, height: 74)
                    Circle().stroke(.pink, lineWidth: 6).frame(width: 64, height: 64)
                    if camera.isCapturing { ProgressView().tint(.pink) }
                }
            }
            .disabled(camera.isCapturing || camera.isTransitioning || camera.permissionState != .ready)
            .buttonStyle(ShutterButtonStyle())
            .accessibilityLabel("拍照")

            Spacer()

            controlButton(systemImage: "camera.rotate.fill", action: camera.switchCamera)
                .disabled(camera.isPictureInPictureEnabled || camera.isTransitioning || camera.isCapturing)
                .accessibilityLabel("切换前后镜头")
        }
        .font(.title2)
        .foregroundStyle(.white)
        .shadow(radius: 4)
    }

    private func sideQuickActions(bottomInset: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 14) {
                    ForEach(CameraControlGrouping.quickActions) { action in
                        quickActionButton(for: action)
                    }
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, 118 + bottomInset)
        }
    }

    private func controlButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.3), in: Circle())
        }
    }

    private var settingsControl: some View {
        HStack(spacing: 12) {
            if isSettingsExpanded {
                ForEach(CameraControlGrouping.expandedSettingsActions) { action in
                    expandedSettingsButton(for: action)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    isSettingsExpanded.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.28), in: Circle())
                    .contentShape(Circle())
                    .rotationEffect(.degrees(isSettingsExpanded ? 90 : 0))
            }
            .accessibilityLabel(isSettingsExpanded ? "收起相机设置" : "展开相机设置")
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isSettingsExpanded)
    }

    @ViewBuilder
    private func quickActionButton(for action: CameraControlAction) -> some View {
        switch action {
        case .stickers:
            Button { isStickerTrayPresented = true } label: {
                Text("🐰").font(.title2).frame(width: 48, height: 48).background(.black.opacity(0.3), in: Circle())
            }
                .accessibilityLabel("添加贴纸")
        case .frames:
            controlButton(systemImage: "rectangle.inset.filled") { isFrameTrayPresented = true }
                .accessibilityLabel("选择边框")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func expandedSettingsButton(for action: CameraControlAction) -> some View {
        switch action {
        case .pictureInPicture:
            settingsCircleButton(
                systemImage: camera.isPictureInPictureEnabled ? "rectangle.on.rectangle.fill" : "rectangle.on.rectangle",
                isActive: camera.isPictureInPictureEnabled
            ) {
                camera.setPictureInPictureEnabled(!camera.isPictureInPictureEnabled)
            }
            .disabled(!camera.isPictureInPictureSupported || camera.isTransitioning || camera.isCapturing)
            .accessibilityLabel(camera.isPictureInPictureEnabled ? "关闭画中画双摄" : "开启画中画双摄")
        case .aspectRatio:
            settingsCircleButton(systemImage: aspectRatio.iconName, isActive: aspectRatio == .threeQuarter) {
                aspectRatio = aspectRatio == .fullScreen ? .threeQuarter : .fullScreen
            }
            .accessibilityLabel("拍照尺寸：\(aspectRatio.title)，点按切换")
        case .sound:
            settingsCircleButton(
                systemImage: isCameraSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                isActive: isCameraSoundEnabled
            ) { isCameraSoundEnabled.toggle() }
                .accessibilityLabel(isCameraSoundEnabled ? "关闭拍照音效" : "开启拍照音效")
        default:
            EmptyView()
        }
    }

    private func settingsCircleButton(
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(isActive ? .pink.opacity(0.9) : .black.opacity(0.38), in: Circle())
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
        let pip = camera.capturedFrontImage.map { PictureInPicturePhoto(image: $0, layout: shutterLayout) }
        Task.detached(priority: .userInitiated) {
            do {
                let result = try PhotoComposer().compose(image: image, previewSize: previewSize, layers: layers, frameStyle: frameStyle, pictureInPicture: pip)
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
        shutterLayout = pictureInPictureLayout
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
