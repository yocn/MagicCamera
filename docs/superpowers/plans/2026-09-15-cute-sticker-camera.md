# 萌趣贴纸相机 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建可在 iPhone 实时预览、叠加萌系贴纸、拍摄合成并存入系统照片的离线相机应用。

**Architecture:** SwiftUI 承载相机界面与贴纸画布，`AVCaptureSession` 驱动真实预览和拍照，独立的合成服务将归一化贴纸变换映射至原始图像。权限、会话、贴纸状态和存储分别封装，避免 UI 直接依赖 AVFoundation 或 PhotoKit。

**Tech Stack:** Swift 5.10、SwiftUI、AVFoundation、Photos、Core Graphics、XCTest；iOS 16+。

**Spec:** `docs/superpowers/specs/2026-09-15-cute-sticker-camera-design.md`

## Global Constraints

- 仅支持 iOS 16+，且不引入第三方依赖。
- 默认前置镜头；最终照片必须包含全部贴纸。
- 首版内置离线萌系贴纸，不实现视频、网络、账户或外部导入。

---

### Task 1: 创建工程与可测试贴纸状态模型

**Files:**
- Create: `CuteStickerCamera.xcodeproj/project.pbxproj`
- Create: `CuteStickerCamera/Models/StickerLayer.swift`
- Create: `CuteStickerCameraTests/StickerLayerTests.swift`

**Interfaces:**
- Produces: `StickerLayer(id:assetName:center:scale:rotation:)`、`StickerCanvas.add(assetName:)`、`StickerCanvas.remove(id:)`、`StickerCanvas.undo()`。

- [ ] 先为叠加、删除及撤销写 XCTest；用两个不同贴纸断言层数和最近操作。
- [ ] 运行测试，确认状态模型尚不存在而失败。
- [ ] 实现最小 `StickerLayer` 和 `StickerCanvas`，令测试通过。
- [ ] 重新运行测试。

### Task 2: 实现相机预览、权限和拍照

**Files:**
- Create: `CuteStickerCamera/Camera/CameraService.swift`
- Create: `CuteStickerCamera/Camera/CameraPreview.swift`
- Create: `CuteStickerCameraTests/CameraPermissionStateTests.swift`

**Interfaces:**
- Produces: `CameraService.start()`、`capturePhoto()`、`switchCamera()` 和 `CameraPermissionState`。

- [ ] 先测试相机/照片权限状态到 UI 文案的映射。
- [ ] 运行测试并确认失败。
- [ ] 实现 AVFoundation 会话管理、预览层包装、镜头切换与拍照回调；拒绝状态提供前往设置动作。
- [ ] 重新运行全部测试；在真机手动核对预览、镜头切换和权限拒绝流程。

### Task 3: 实现多贴纸编辑画布与素材抽屉

**Files:**
- Create: `CuteStickerCamera/Views/StickerCanvasView.swift`
- Create: `CuteStickerCamera/Views/StickerTrayView.swift`
- Create: `CuteStickerCamera/Resources/Stickers/*.png`

**Interfaces:**
- Consumes: `StickerCanvas`。
- Produces: 支持拖动、缩放、旋转、删除和撤销的预览叠层。

- [ ] 先测试选择贴纸时以默认中心、比例和零角度插入新层。
- [ ] 运行测试并确认失败。
- [ ] 实现贴纸抽屉与手势画布，新增层不覆盖已有层；用内置 PNG 显示素材。
- [ ] 重新运行全部测试；真机手动检查至少两个贴纸的独立变换。

### Task 4: 合成并保存成片

**Files:**
- Create: `CuteStickerCamera/Services/PhotoComposer.swift`
- Create: `CuteStickerCamera/Services/PhotoLibrarySaver.swift`
- Create: `CuteStickerCameraTests/StickerTransformTests.swift`

**Interfaces:**
- Consumes: 原始 `UIImage`、预览内容矩形和 `[StickerLayer]`。
- Produces: `compose(image:previewSize:layers:) throws -> UIImage` 与 `save(_:) async throws`。

- [ ] 先测试归一化贴纸中心、缩放和角度映射到目标图像的矩阵计算。
- [ ] 运行测试并确认失败。
- [ ] 实现 Core Graphics 合成与 PhotoKit 保存，保留方向/镜像修正；保存失败显示中文错误。
- [ ] 重新运行全部测试；真机拍摄一张带多个变换贴纸的照片，并在系统照片核对成片。

### Task 5: 组合主界面与自用照片跳转

**Files:**
- Create: `CuteStickerCamera/App/CuteStickerCameraApp.swift`
- Create: `CuteStickerCamera/Views/CameraScreen.swift`
- Create: `CuteStickerCameraTests/PhotoLaunchFallbackTests.swift`

**Interfaces:**
- Consumes: `CameraService`、`StickerCanvas`、`PhotoComposer`、`PhotoLibrarySaver`。
- Produces: 完整拍摄流程与不可用跳转的提示回退。

- [ ] 先测试系统照片跳转不可用时返回“已保存，请打开照片 App”的提示状态。
- [ ] 运行测试并确认失败。
- [ ] 实现主界面、快门防重复点击、保存反馈和 `photos-redirect://` 尝试；不能打开时使用回退提示。
- [ ] 重新运行全部测试，并在真机完成完整拍摄、保存、跳转与权限拒绝的验收。
