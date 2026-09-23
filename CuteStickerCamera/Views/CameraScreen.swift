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
    @State private var recentPhotos = RecentPhotoStore()
    @State private var message: String?
    @AppStorage(CameraSoundPreference.storageKey) private var isCameraSoundEnabled = true
    @AppStorage(CameraTimerPreference.storageKey) private var isTimerEnabled = false
    @State private var isShutterFlashVisible = false
    @State private var timerCountdown: Int?
    @State private var timerCaptureToken: UUID?
    @State private var pictureInPictureLayout = PictureInPictureLayout()
    @State private var shutterLayout = PictureInPictureLayout()
    @State private var isSettingsExpanded = false
    @State private var isCollageTrayPresented = false
    @State private var collageLayout: CollageLayout = .fourGrid
    @State private var collageStyle: CollageStyle = .classicWhite
    @State private var collageMode: CollageCaptureMode = .burstThree
    @State private var collageSession: CollageSession?
    @State private var collageShots: [UIImage] = []
    @State private var collageToken: UUID?
    @State private var collageOverlayLayout = CollageOverlayLayout()
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

                Color.black
                    .opacity(camera.isTransitioning ? CameraSwitchAnimation.dimmingOpacity : 0)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .animation(.easeInOut(duration: CameraSwitchAnimation.dimmingDuration), value: camera.isTransitioning)
                    .allowsHitTesting(false)

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

                if let session = collageSession {
                    CollageProgressView(
                        session: session,
                        thumbnails: collageShots,
                        isCapturing: session.capturedCount > 0 || collageToken != nil,
                        overlayLayout: $collageOverlayLayout,
                        canvasSize: contentRect.size,
                        onClose: { cancelCollage() }
                    )
                    .frame(width: contentRect.width, height: contentRect.height)
                    .coordinateSpace(name: "collageCanvas")
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .allowsHitTesting(!camera.isCapturing)
                }

                if camera.isTransitioning {
                    CameraSwitchIndicator()
                        .position(x: contentRect.midX, y: contentRect.midY)
                }

                Color.black
                    .opacity(isShutterFlashVisible ? 1 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.18), value: isShutterFlashVisible)

                if let timerCountdown {
                    timerCountdownOverlay(value: timerCountdown)
                        .id(timerCountdown)
                }

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
                } onMagicPick: {
                    let outfit = MagicStickerOutfits.random()
                    canvas.add(layers: outfit.placements.map(\.layer))
                    message = "\(outfit.title)搭配完成 ✨"
                    isStickerTrayPresented = false
                } onClose: {
                    isStickerTrayPresented = false
                }
                .presentationDetents([.height(500)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
            .sheet(isPresented: $isFrameTrayPresented) {
                FrameTrayView(selected: frameStyle) { style in
                    frameStyle = style
                    isFrameTrayPresented = false
                }
                .presentationDetents([.height(210)])
                .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $isCollageTrayPresented) {
                CollageTrayView(
                    layout: $collageLayout,
                    style: $collageStyle,
                    mode: $collageMode,
                    onSelect: enableCollageMode,
                    onClose: { isCollageTrayPresented = false }
                )
                .presentationDetents([.height(358)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
            .onAppear { camera.start() }
            .onDisappear {
                cancelTimerCapture()
                suspendCollageCountdown()
                camera.stop()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active { camera.start() }
                if phase == .background {
                    cancelTimerCapture()
                    suspendCollageCountdown()
                    camera.stop()
                }
            }
            .onChange(of: camera.permissionState) { state in
                guard state != .ready else { return }
                suspendCollageCountdown()
            }
            .onChange(of: camera.cameraMessage) { cameraMessage in
                guard cameraMessage != nil else { return }
                suspendCollageCountdown()
            }
            .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
                if collageSession == nil {
                    saveComposed(image, previewSize: contentRect.size, frameStyle: frameStyle)
                } else {
                    handleCollageShot(image, previewSize: contentRect.size, frameStyle: frameStyle)
                }
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
            recentPhotoButton

            Spacer()

            Button(action: triggerCapture) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.62))
                        .frame(width: SystemCameraShutter.outerDiameter, height: SystemCameraShutter.outerDiameter)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.48), lineWidth: SystemCameraShutter.ringLineWidth)
                        )
                    Circle()
                        .fill(.white)
                        .frame(width: SystemCameraShutter.innerDiameter, height: SystemCameraShutter.innerDiameter)
                    if camera.isCapturing { ProgressView().tint(.black.opacity(0.65)) }
                }
            }
            .disabled(timerCountdown != nil || camera.isCapturing || camera.isTransitioning || camera.permissionState != .ready)
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

    private var recentPhotoButton: some View {
        Button(action: openSystemPhotos) {
            Group {
                if let thumbnail = recentPhotoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2.weight(.semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(.black.opacity(0.3), in: Circle())
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(recentPhotoThumbnail == nil ? 0 : 0.65), lineWidth: 2))
        }
        .accessibilityLabel(recentPhotoThumbnail == nil ? "打开系统照片" : "打开最近拍摄的照片")
    }

    private var recentPhotoThumbnail: UIImage? {
        guard let photo = recentPhotos.items.first,
              let data = try? recentPhotos.data(for: photo) else {
            return nil
        }
        return UIImage(data: data)
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
            quickCircleButton(systemImage: "rectangle.inset.filled", isActive: frameStyle != .none) {
                isFrameTrayPresented = true
            }
            .accessibilityLabel("选择边框")
        case .collage:
            quickCircleButton(systemImage: "square.grid.2x2.fill", isActive: collageSession != nil) {
                isCollageTrayPresented = true
            }
            .accessibilityLabel("大头贴")
        default:
            EmptyView()
        }
    }

    /// 未生效时和右上角设置按钮同款，生效后图标转为高亮色。
    private func quickCircleButton(
        systemImage: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(isActive ? Color.blue : Color.white)
                .frame(width: 48, height: 48)
                .background(.black.opacity(0.3), in: Circle())
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
            .disabled(collageSession != nil)
            .accessibilityLabel("拍照尺寸：\(aspectRatio.title)，点按切换")
        case .sound:
            settingsCircleButton(
                systemImage: isCameraSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                isActive: isCameraSoundEnabled
            ) { isCameraSoundEnabled.toggle() }
                .accessibilityLabel(isCameraSoundEnabled ? "关闭拍照音效" : "开启拍照音效")
        case .timer:
            settingsCircleButton(systemImage: "timer", isActive: isTimerEnabled) {
                isTimerEnabled.toggle()
            }
            .accessibilityLabel(isTimerEnabled ? "关闭 3 秒定时拍照" : "开启 3 秒定时拍照")
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
                let thumbnailData = result.jpegData(compressionQuality: 0.82)
                if let thumbnailData {
                    await MainActor.run {
                        do {
                            try recentPhotos.store(data: thumbnailData)
                        } catch {
                            // The system photo save still proceeds if the lightweight recent-photo cache is unavailable.
                        }
                    }
                }
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

    private func triggerCapture() {
        if let session = collageSession {
            guard let seconds = session.mode.countdownSeconds else {
                capturePhoto()
                return
            }
            guard collageToken == nil else { return }
            beginCollageBurst(seconds: seconds)
            return
        }
        guard isTimerEnabled else {
            capturePhoto()
            return
        }
        startTimerCapture()
    }

    private func startTimerCapture() {
        guard timerCountdown == nil else { return }
        let token = UUID()
        timerCaptureToken = token
        timerCountdown = 3

        Task {
            for value in stride(from: 3, through: 1, by: -1) {
                guard timerCaptureToken == token else { return }
                timerCountdown = value
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
            }
            guard timerCaptureToken == token else { return }
            timerCaptureToken = nil
            timerCountdown = nil
            capturePhoto()
        }
    }

    private func cancelTimerCapture() {
        timerCaptureToken = nil
        timerCountdown = nil
    }

    /// 开启模式或换选项都走这里；换选项会作废已拍的格子，但保留浮层位置。
    private func enableCollageMode() {
        if collageSession == nil { collageOverlayLayout = CollageOverlayLayout() }
        collageToken = nil
        timerCountdown = nil
        collageShots = []
        collageSession = CollageSession(layout: collageLayout, style: collageStyle, mode: collageMode)
    }

    private func beginCollageBurst(seconds: Int) {
        let token = UUID()
        collageToken = token
        Task { await runCollageCountdown(seconds: seconds, token: token) }
    }

    private func handleCollageShot(_ image: UIImage, previewSize: CGSize, frameStyle: FrameStyle) {
        guard collageSession != nil else { return }
        let layers = canvas.layers
        let pip = camera.capturedFrontImage.map { PictureInPicturePhoto(image: $0, layout: shutterLayout) }

        Task.detached(priority: .userInitiated) {
            let shot = try? PhotoComposer().compose(
                image: image,
                previewSize: previewSize,
                layers: layers,
                frameStyle: frameStyle,
                pictureInPicture: pip
            )
            await MainActor.run {
                // 合成期间可能已被取消或重开，这里必须重新取当前 session。
                guard var session = collageSession else { return }
                guard let shot else {
                    // 这一轮作废重来，但留在大头贴模式里。
                    enableCollageMode()
                    message = PhotoComposerError.unableToCreateImage.errorDescription
                    return
                }
                collageShots.append(shot)
                session.advance()
                collageSession = session
                if session.isComplete {
                    finishCollage(session)
                } else if let seconds = session.mode.countdownSeconds {
                    let token = UUID()
                    collageToken = token
                    Task {
                        try? await Task.sleep(nanoseconds: UInt64(CollageCaptureTiming.shotInterval * 1_000_000_000))
                        guard collageToken == token else { return }
                        await runCollageCountdown(seconds: seconds, token: token)
                    }
                }
            }
        }
    }

    private func runCollageCountdown(seconds: Int, token: UUID) async {
        for value in stride(from: seconds, through: 1, by: -1) {
            guard collageToken == token else { return }
            timerCountdown = value
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        guard collageToken == token else { return }
        timerCountdown = nil
        capturePhoto()
    }

    private func finishCollage(_ session: CollageSession) {
        let shots = collageShots
        let layout = session.layout
        let style = session.style
        // 保留模式与配置，直接开下一轮；退出只由浮层的关闭按钮触发。
        collageSession = CollageSession(layout: layout, style: style, mode: session.mode)
        collageShots = []
        collageToken = nil
        timerCountdown = nil
        saveTracker.beginSave()

        Task.detached(priority: .userInitiated) {
            do {
                let result = try CollageComposer().compose(shots: shots, layout: layout, style: style)
                if let data = result.jpegData(compressionQuality: 0.82) {
                    await MainActor.run { try? recentPhotos.store(data: data) }
                }
                try await PhotoLibrarySaver().save(result)
                await MainActor.run {
                    saveTracker.finishSave()
                    message = "大头贴拍好啦！已经保存到系统照片 ✨"
                }
            } catch {
                await MainActor.run {
                    saveTracker.finishSave()
                    message = error.localizedDescription
                }
            }
        }
    }

    /// 退出大头贴模式，只由浮层的关闭按钮触发。
    private func cancelCollage() {
        collageToken = nil
        collageSession = nil
        collageShots = []
        timerCountdown = nil
    }

    /// 相机停了就停掉倒计时，模式、配置和已拍的格子都留着，回到前台能接着拍。
    private func suspendCollageCountdown() {
        guard collageSession != nil else { return }
        collageToken = nil
        timerCountdown = nil
    }

    private func timerCountdownOverlay(value: Int) -> some View {
        TimerCountdownDigitView(value: value)
    }

    private func openSystemPhotos() {
        guard let url = URL(string: "photos-redirect://") else { return }
        UIApplication.shared.open(url) { success in
            if !success { message = "照片已保存，请打开“照片”App 继续编辑。" }
        }
    }
}

private struct TimerCountdownDigitView: View {
    let value: Int
    @State private var scale = TimerCountdownAnimation.initialScale

    var body: some View {
        Text("\(value)")
            .font(.system(size: 152, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
            .scaleEffect(scale)
            .allowsHitTesting(false)
            .accessibilityLabel("定时拍照倒计时：\(value)")
            .onAppear {
                withAnimation(.easeOut(duration: TimerCountdownAnimation.duration)) {
                    scale = TimerCountdownAnimation.finalScale
                }
            }
    }
}

private struct CameraSwitchIndicator: View {
    @State private var scale = CameraSwitchAnimation.indicatorStartScale
    @State private var opacity = 0.0

    var body: some View {
        Image(systemName: "camera.rotate.fill")
            .font(.system(size: 34, weight: .semibold))
            .foregroundStyle(.white)
            .frame(
                width: CameraSwitchAnimation.indicatorDiameter,
                height: CameraSwitchAnimation.indicatorDiameter
            )
            .background(.black.opacity(0.42), in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: CameraSwitchAnimation.indicatorFadeInDuration)) {
                    scale = 1
                    opacity = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + CameraSwitchAnimation.indicatorFadeInDuration) {
                    withAnimation(.easeIn(duration: CameraSwitchAnimation.indicatorFadeDuration)) {
                        scale = 0.78
                        opacity = 0
                    }
                }
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
