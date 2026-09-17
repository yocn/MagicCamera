# 双摄画中画 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** 在支持的 iPhone 上实现后摄主画面、可拖动前摄小窗和双摄合成拍照；不支持时保持当前单摄体验。

**Architecture:** 用 \`PictureInPictureLayout\` 管理小窗几何。CameraService 在单摄和 \`AVCaptureMultiCamSession\` 间安全切换，后摄 PhotoOutput 提供主图，前摄 VideoDataOutput 缓存最近帧；PhotoComposer 合成小窗、贴纸和边框。

**Tech Stack:** Swift 5、SwiftUI、UIKit、AVFoundation、XCTest。

**Spec:** \`docs/superpowers/specs/2026-09-17-dual-camera-picture-in-picture-design.md\`

## Global Constraints

- 最低部署版本 iOS 16.0；不引入第三方依赖。
- 仅在 \`AVCaptureMultiCamSession.isMultiCamSupported\` 且实际设备组合可用时显示入口。
- 首版只支持静态拍照，不录制双摄视频。
- 小窗使用主画幅短边的 30%，圆角 14%，白色描边 1.5%。
- 不支持、配置失败、会话中断或压力超限时必须退回单摄。
- 贴纸和边框始终位于画中画合成之上。

---

### Task 1: 画中画布局模型

**Files:**
- Create: \`CuteStickerCamera/Core/PictureInPictureLayout.swift\`
- Modify: \`CuteStickerCameraTests/Core/StickerRenderTransformTests.swift\`

**Interfaces:** Produces \`PictureInPictureLayout(center: CGPoint = CGPoint(x: 0.82, y: 0.18))\`, \`rect(in:)\`, and \`normalizedCenter(afterDragging:in:)\`.

- [ ] **Step 1: Write failing tests**

\`\`\`swift
func testPictureInPictureUsesThirtyPercentOfShortestSideAtUpperRight() {
    let rect = PictureInPictureLayout().rect(in: CGSize(width: 400, height: 800))
    XCTAssertEqual(rect, CGRect(x: 264, y: 24, width: 120, height: 120))
}

func testPictureInPictureDraggingClampsWindowInsideCanvas() {
    let layout = PictureInPictureLayout(center: CGPoint(x: 0.95, y: 0.05))
    XCTAssertEqual(layout.normalizedCenter(afterDragging: .zero, in: CGSize(width: 400, height: 800)), CGPoint(x: 0.85, y: 0.15))
}
\`\`\`

- [ ] **Step 2: Verify red**

Run:
\`\`\`bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -only-testing:CuteStickerCameraTests/StickerRenderTransformTests test CODE_SIGNING_ALLOWED=NO
\`\`\`
Expected: failure because \`PictureInPictureLayout\` is absent.

- [ ] **Step 3: Implement the model**

\`\`\`swift
struct PictureInPictureLayout: Equatable {
    static let sideFraction: CGFloat = 0.30
    var center: CGPoint
    init(center: CGPoint = CGPoint(x: 0.82, y: 0.18)) { self.center = center }
    func rect(in canvas: CGSize) -> CGRect {
        let side = min(canvas.width, canvas.height) * Self.sideFraction
        return CGRect(x: center.x * canvas.width - side / 2, y: center.y * canvas.height - side / 2, width: side, height: side)
    }
    func normalizedCenter(afterDragging translation: CGSize, in canvas: CGSize) -> CGPoint {
        let side = min(canvas.width, canvas.height) * Self.sideFraction
        return CGPoint(x: min(1 - side / canvas.width / 2, max(side / canvas.width / 2, center.x + translation.width / canvas.width)), y: min(1 - side / canvas.height / 2, max(side / canvas.height / 2, center.y + translation.height / canvas.height)))
    }
}
\`\`\`

- [ ] **Step 4: Verify green and commit**

Run the Step 2 command, then:
\`\`\`bash
git add CuteStickerCamera/Core/PictureInPictureLayout.swift CuteStickerCameraTests/Core/StickerRenderTransformTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m 'feat(双摄画中画): 添加小窗布局模型'
\`\`\`

### Task 2: 双摄静态照片合成

**Files:**
- Modify: \`CuteStickerCamera/Services/PhotoComposer.swift\`
- Modify: \`CuteStickerCameraTests/Core/StickerRenderTransformTests.swift\`

**Interfaces:** Produces \`PictureInPicturePhoto(image: UIImage, layout: PictureInPictureLayout)\` and extends \`compose(image:previewSize:layers:frameStyle:pictureInPicture:)\` with a default nil final parameter.

- [ ] **Step 1: Write the failing composition test**

\`\`\`swift
func testComposerDrawsFrontCameraWindowAboveMainPhoto() throws {
    let result = try PhotoComposer().compose(
        image: solidImage(color: .blue, size: CGSize(width: 400, height: 800)),
        previewSize: CGSize(width: 400, height: 800), layers: [],
        pictureInPicture: PictureInPicturePhoto(
            image: solidImage(color: .red, size: CGSize(width: 100, height: 100)),
            layout: PictureInPictureLayout()
        )
    )
    XCTAssertEqual(result.pixelColor(at: CGPoint(x: 324, y: 84)), .red)
}
\`\`\`

- [ ] **Step 2: Verify red**

Run the Task 1 test command. Expected: compile failure because the new photo input and composer argument are absent.

- [ ] **Step 3: Draw the rounded, white-outlined front window before sticker/frame layers**

\`\`\`swift
let rect = pictureInPicture.layout.rect(in: canvas.size)
context.cgContext.saveGState()
UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.14).addClip()
pictureInPicture.image.draw(in: rect)
context.cgContext.restoreGState()
UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.14).stroke()
\`\`\`

- [ ] **Step 4: Verify green and commit**

Run the Task 1 test command, then:
\`\`\`bash
git add CuteStickerCamera/Services/PhotoComposer.swift CuteStickerCameraTests/Core/StickerRenderTransformTests.swift
git commit -m 'feat(双摄画中画): 合成前摄小窗照片'
\`\`\`

### Task 3: 多摄能力与会话

**Files:**
- Create: \`CuteStickerCamera/Camera/MultiCameraSupport.swift\`
- Modify: \`CuteStickerCamera/Camera/CameraService.swift\`
- Modify: \`CuteStickerCamera/Camera/CameraPreview.swift\`
- Modify: \`CuteStickerCameraTests/Core/StickerCanvasTests.swift\`

**Interfaces:** Extends CameraService with \`isPictureInPictureSupported\`, \`isPictureInPictureEnabled\`, \`frontCameraImage\`, and \`setPictureInPictureEnabled(_:)\`.

- [ ] **Step 1: Write the failing support test**

\`\`\`swift
func testUnsupportedDevicesDoNotExposePictureInPictureToggle() {
    XCTAssertFalse(MultiCameraSupport(isSupported: false).showsPictureInPictureToggle)
    XCTAssertTrue(MultiCameraSupport(isSupported: true).showsPictureInPictureToggle)
}
\`\`\`

- [ ] **Step 2: Verify red**

Run:
\`\`\`bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -only-testing:CuteStickerCameraTests/StickerCanvasTests test CODE_SIGNING_ALLOWED=NO
\`\`\`
Expected: compilation fails because \`MultiCameraSupport\` is absent.

- [ ] **Step 3: Implement safe multi-cam configuration**

\`\`\`swift
guard AVCaptureMultiCamSession.isMultiCamSupported else { return fallbackToSingleCamera() }
let multiCamSession = AVCaptureMultiCamSession()
multiCamSession.beginConfiguration()
multiCamSession.sessionPreset = .inputPriority
let rearInput = try AVCaptureDeviceInput(device: rearDevice)
let frontInput = try AVCaptureDeviceInput(device: frontDevice)
multiCamSession.addInputWithNoConnections(rearInput)
multiCamSession.addInputWithNoConnections(frontInput)
multiCamSession.addOutputWithNoConnections(rearPhotoOutput)
multiCamSession.addOutputWithNoConnections(frontVideoOutput)
multiCamSession.addConnection(AVCaptureConnection(inputPorts: [rearPort], output: rearPhotoOutput))
multiCamSession.addConnection(AVCaptureConnection(inputPorts: [frontPort], output: frontVideoOutput))
multiCamSession.commitConfiguration()
\`\`\`

Cache the latest front CMSampleBuffer as a mirrored UIImage on a serial queue. On any configuration error, interruption, critical hardware cost, or critical system pressure, stop multi-cam and restore the current single-camera session.

- [ ] **Step 4: Add explicit preview connections**

\`\`\`swift
let rearLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: multiCamSession)
let rearConnection = AVCaptureConnection(inputPorts: [rearPort], videoPreviewLayer: rearLayer)
let frontLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: multiCamSession)
let frontConnection = AVCaptureConnection(inputPorts: [frontPort], videoPreviewLayer: frontLayer)
multiCamSession.addConnection(rearConnection)
multiCamSession.addConnection(frontConnection)
\`\`\`

Store both preview connections and remove them, plus the two output connections, in `stopPictureInPictureSession()` before restoring the single-camera configuration.

- [ ] **Step 5: Verify green and commit**

Run the Step 2 command. Simulator must show no dual-camera toggle. Then:
\`\`\`bash
git add CuteStickerCamera/Camera/MultiCameraSupport.swift CuteStickerCamera/Camera/CameraService.swift CuteStickerCamera/Camera/CameraPreview.swift CuteStickerCameraTests/Core/StickerCanvasTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m 'feat(双摄画中画): 接入多摄会话能力'
\`\`\`

### Task 4: 画中画设置、预览与拍照入口

**Files:**
- Create: \`CuteStickerCamera/Views/PictureInPicturePreview.swift\`
- Modify: \`CuteStickerCamera/Views/CameraScreen.swift\`
- Modify: \`CuteStickerCamera/Core/CameraControlGrouping.swift\`
- Modify: \`CuteStickerCameraTests/Core/StickerCanvasTests.swift\`

**Interfaces:** PictureInPicturePreview receives CameraService, a binding to PictureInPictureLayout, and main canvas size. CameraScreen passes PictureInPicturePhoto to PhotoComposer only when mode and cached front image are present.

- [ ] **Step 1: Write the failing settings-list test**

\`\`\`swift
func testSupportedCameraSettingsIncludePictureInPictureAction() {
    XCTAssertEqual(CameraControlGrouping.settingsActions(supportsPictureInPicture: true), [.switchCamera, .aspectRatio, .sound, .pictureInPicture])
}
\`\`\`

- [ ] **Step 2: Verify red**

Run the Task 3 test command. Expected: compilation fails because the picture-in-picture setting action is absent.

- [ ] **Step 3: Implement settings toggle and draggable overlay**

\`\`\`swift
if camera.isPictureInPictureSupported {
    Toggle("画中画双摄", isOn: Binding(
        get: { camera.isPictureInPictureEnabled },
        set: { camera.setPictureInPictureEnabled($0) }
    ))
}
\`\`\`

Place the front preview inside contentRect. Use DragGesture and normalizedCenter(afterDragging:in:) to keep the window inside the main canvas.

- [ ] **Step 4: Connect photo composition**

\`\`\`swift
let pip = camera.isPictureInPictureEnabled
    ? camera.frontCameraImage.map { PictureInPicturePhoto(image: $0, layout: pictureInPictureLayout) }
    : nil
\`\`\`

Pass pip to PhotoComposer from saveComposed.

- [ ] **Step 5: Verify full suite and commit**

Run:
\`\`\`bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test CODE_SIGNING_ALLOWED=NO
\`\`\`
Then:
\`\`\`bash
git add CuteStickerCamera/Views/PictureInPicturePreview.swift CuteStickerCamera/Views/CameraScreen.swift CuteStickerCamera/Core/CameraControlGrouping.swift CuteStickerCameraTests/Core/StickerCanvasTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m 'feat(双摄画中画): 添加双摄预览与拍照入口'
\`\`\`

### Task 5: 真机验收

**Files:**
- Modify: \`docs/superpowers/specs/2026-09-17-dual-camera-picture-in-picture-design.md\` only if verified device-specific behavior differs from the design.

- [ ] **Step 1: Build for connected physical iPhone**

\`\`\`bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'id=00008140-000244421AE1801C' build
\`\`\`

Expected: ** BUILD SUCCEEDED **.

- [ ] **Step 2: Exercise multi-cam mode**

Install with devicectl, enable “画中画双摄”, verify front/rear previews, drag the window, capture ten still images, and inspect saved ordering.

- [ ] **Step 3: Verify fallback and final checks**

On simulator, confirm no dual-camera toggle. Run the Task 4 full suite and \`git diff --check\`.
