# 双摄画中画 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在支持设备上提供后摄主预览、前摄可拖动画中画小窗，并在照片中合成两路画面、贴纸和边框。

**Architecture:** 将双摄能力检测与画中画几何从 AVFoundation 和视图中分离，保持单摄默认路径不变。双摄使用 `AVCaptureMultiCamSession`；主路静态照片与前摄最近视频帧交给 `PhotoComposer` 合成。

**Tech Stack:** Swift 5、SwiftUI、UIKit、AVFoundation、Photos、XCTest。

**Spec:** `docs/superpowers/specs/2026-09-17-dual-camera-picture-in-picture-design.md`

## Global Constraints

- iOS 16 起，不增加第三方依赖。
- 仅在 `AVCaptureMultiCamSession.isMultiCamSupported` 和受支持设备组合都满足时显示入口。
- 首版仅拍静态照片；前摄小窗为主画幅短边的 30%。
- 不支持、配置失败、会话中断或资源压力过高时回退单摄并显示中文提示。
- 现有贴纸、边框、画幅、系统相册保存与音效必须继续工作。

---

### Task 1: 双摄能力与画中画几何

**Files:**
- Create: `CuteStickerCamera/Core/PictureInPictureLayout.swift`
- Create: `CuteStickerCamera/Core/MultiCameraCapability.swift`
- Modify: `CuteStickerCameraTests/Core/StickerRenderTransformTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces `PictureInPictureLayout.default`, `frame(in:)`, `moved(to:in:)`.
- Produces `MultiCameraCapability` and a pure `MultiCameraCapabilityEvaluator`.

- [ ] Write a failing test for a 400×800 canvas: default inset must be `CGRect(x: 248, y: 32, width: 120, height: 120)`.
- [ ] Run the targeted transform test; expect compile failure because the layout does not exist.
- [ ] Implement a normalized center, 30%-short-side square size, and clamped drag bounds; implement a pure evaluator that rejects unsupported runtime values or device-pair lists.
- [ ] Add new files to the Xcode project and re-run targeted tests; expect zero failures.
- [ ] Commit with `feat(双摄画中画): 增加能力检测与小窗布局`.

### Task 2: 画中画照片合成

**Files:**
- Modify: `CuteStickerCamera/Services/PhotoComposer.swift`
- Modify: `CuteStickerCameraTests/Core/StickerRenderTransformTests.swift`

**Interfaces:**
- Consumes `PictureInPictureLayout`.
- Extends `PhotoComposer.compose(image:previewSize:layers:frameStyle:pictureInPicture:)` with optional `PictureInPicturePhoto`.

- [ ] Write a failing test using blue main and red front solid images; after composition, a pixel inside the default inset must be red.
- [ ] Run the targeted transform test; expect missing picture-in-picture composition API.
- [ ] Implement cropping of the main image, mirrored front-frame drawing clipped by `UIBezierPath(roundedRect:cornerRadius:)`, and white inset border before existing stickers/frame draw calls.
- [ ] Re-run targeted tests; expect zero failures.
- [ ] Commit with `feat(双摄画中画): 合成前摄小窗照片`.

### Task 3: 多摄会话与双摄预览

**Files:**
- Modify: `CuteStickerCamera/Camera/CameraService.swift`
- Modify: `CuteStickerCamera/Camera/CameraPreview.swift`
- Create: `CuteStickerCamera/Views/PictureInPicturePreview.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces `isMultiCamAvailable`, `isPictureInPictureEnabled`, `latestFrontCameraImage`, and `setPictureInPictureEnabled(_:)` from `CameraService`.
- Produces an independently framed front preview view bound to the multi-camera session.

- [ ] Write a failing capability-state test for `MultiCameraCapability.unsupported`.
- [ ] Run it; expect compile failure due to missing unsupported capability constructor.
- [ ] On the session queue, configure `AVCaptureMultiCamSession` with front/back inputs, a back photo output, and low-resolution front video-data output. Cache the latest normalized front frame.
- [ ] Stop before changing session topology and restart after configuration; on invalid device pair, configuration error, interruption, or resource limit publish fallback state and restore single camera.
- [ ] Re-run targeted tests and a signed-off simulator build; expect zero failures and build success.
- [ ] Commit with `feat(双摄画中画): 配置前后摄同步预览`.

### Task 4: 主界面开关、小窗拖动与保存

**Files:**
- Modify: `CuteStickerCamera/Views/CameraScreen.swift`
- Modify: `CuteStickerCamera/Views/PictureInPicturePreview.swift`
- Modify: `CuteStickerCamera/Core/CameraControlGrouping.swift`
- Modify: `CuteStickerCameraTests/Core/StickerCanvasTests.swift`

**Interfaces:**
- Consumes camera double-camera state and `PictureInPictureLayout`.
- Uses `PhotoComposer.compose(...pictureInPicture:)` when a cached front image is present.

- [ ] Write a failing grouping test: settings include `.pictureInPicture` only when multi-camera is available.
- [ ] Run it; expect missing setting action/grouping API.
- [ ] Add the upper-right settings toggle; render the inset above main preview and below stickers/frame; update its normalized center from drag gestures.
- [ ] Pass the front image and layout to the composer, using the existing message overlay for fallback notices.
- [ ] Run complete simulator tests and manually verify all single-camera regressions plus absence of the dual-camera setting in the simulator.
- [ ] Build and install on the connected supported iPhone; enable dual-camera, drag the inset, take ten photos, and verify the inset, stickers, and frame in each saved photo.
- [ ] Commit with `feat(双摄画中画): 接入设置与拍照成片`, then push `main`.
