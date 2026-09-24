# 涂鸦图层 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在相机预览上叠一层透明画布，手指直接涂鸦，拍照时把涂鸦合成进成片。

**Architecture:** 工具状态（颜色、粗细、橡皮）作为纯逻辑放进 `Core/`，可单测。绘制交给 `PKCanvasView`，藏掉系统工具箱、由自己的按钮驱动。涂鸦层夹在贴纸和边框之间，非涂鸦模式下关掉交互让手势穿透回贴纸。

**Tech Stack:** Swift、SwiftUI、PencilKit、UIKit、XCTest。

**Spec:** `docs/superpowers/specs/2026-09-24-doodle-layer-design.md`

## Global Constraints

- 最低部署版本 iOS 16.0，不引入第三方依赖。
- `Core/` 下的新文件只能 import `Foundation` / `CoreGraphics`，不得 import UIKit 或 PencilKit，否则 SPM target 编译失败。
- 注释一行为限，只写非显而易见的约束。
- commit message 格式 `<type>(<scope>): <中文描述>`，只有标题行，不加 `Co-Authored-By`。
- **每次 commit 前必须向用户显式请求许可**（用户全局规范，覆盖本计划里的 commit 步骤）。
- 新增源文件必须登记进 `project.pbxproj`，用 `/tmp/pbx_add.py <pbxproj> <文件名> <BuildID> <FileID> <锚点文件名> <锚点BuildID> <锚点FileID>`。执行前先跑 `grep -oE "B0[0-9][0-9]" project.pbxproj | sort -u | tail -1` 查当前最大 ID，往后顺延，避免和 codex 并行新增的文件撞号。

## 关键 API（已核对 iOS 27.0 SDK，勿凭记忆改写）

```swift
PKInkingTool(_ inkType: PKInkingTool.InkType, color: UIColor = .black, width: CGFloat? = nil)
PKEraserTool(_ eraserType: PKEraserTool.EraserType, width: CGFloat)
PKDrawing.image(from rect: CGRect, scale: CGFloat) -> UIImage
PKCanvasView.drawingPolicy: PKCanvasViewDrawingPolicy   // .default / .anyInput / .pencilOnly
```

`drawingPolicy` 必须显式设成 `.anyInput`，默认值会拒绝手指输入。

## 测试命令

```sh
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera \
  -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

注意：仓库里当前已有 4 个来自 codex 的失败用例（`testEveryFrameTabOffersAtLeastTenDecorativeChoices`，要求每个边框分类至少 10 个）。这些与本计划无关，判断成败时只看新增用例和原本通过的用例有没有变红。

---

### Task 1: 涂鸦工具状态

**Files:**
- Create: `CuteStickerCamera/Core/DoodleTool.swift`
- Create: `CuteStickerCameraTests/Core/DoodleTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

- [ ] **Step 1: 登记两个新文件**

先查最大 ID：

```sh
grep -oE "B0[0-9][0-9]" CuteStickerCamera.xcodeproj/project.pbxproj | sort -u | tail -1
grep -oE "F0[0-9][0-9]" CuteStickerCamera.xcodeproj/project.pbxproj | sort -u | tail -1
```

用顺延的 ID 登记（下面假设查到的是 B039/F041，实际以查询结果为准）：

```sh
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj DoodleTool.swift B040 F042 CollageSession.swift B029 F031
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj DoodleTests.swift B204 F204 CollageTests.swift B203 F203
```

- [ ] **Step 2: 写失败的测试**

创建 `CuteStickerCameraTests/Core/DoodleTests.swift`：

```swift
import CoreGraphics
import XCTest
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class DoodleTests: XCTestCase {
    func testPaletteOffersEightDistinctColors() {
        XCTAssertEqual(DoodlePalette.all.count, 8)

        let ids = Set(DoodlePalette.all.map(\.id))
        XCTAssertEqual(ids.count, 8, "调色板里有重复的颜色 id")

        let titles = Set(DoodlePalette.all.map(\.title))
        XCTAssertEqual(titles.count, 8, "调色板里有重复的颜色名")
    }

    func testBrushWidthsIncreaseStrictly() {
        let sizes = DoodleBrushWidth.allCases.map(\.pointSize)

        XCTAssertEqual(sizes, sizes.sorted(), "粗细档位没有按从细到粗排列")
        XCTAssertEqual(Set(sizes).count, sizes.count, "存在两档粗细一样")
        XCTAssertEqual(DoodleBrushWidth.thin.pointSize, 6, accuracy: 0.0001)
        XCTAssertEqual(DoodleBrushWidth.medium.pointSize, 14, accuracy: 0.0001)
        XCTAssertEqual(DoodleBrushWidth.thick.pointSize, 26, accuracy: 0.0001)
    }

    func testTogglingEraserKeepsPenSettings() {
        var state = DoodleToolState()
        state.color = DoodlePalette.all[4]
        state.width = .thick

        state.isErasing = true
        XCTAssertEqual(state.color, DoodlePalette.all[4], "切到橡皮时不该丢掉颜色")
        XCTAssertEqual(state.width, .thick, "切到橡皮时不该丢掉粗细")

        state.isErasing = false
        XCTAssertEqual(state.color, DoodlePalette.all[4])
        XCTAssertEqual(state.width, .thick)
    }

    func testDefaultToolIsMediumBubblePink() {
        let state = DoodleToolState()

        XCTAssertEqual(state.color.id, "bubble")
        XCTAssertEqual(state.width, .medium)
        XCTAssertFalse(state.isErasing)
    }
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: 上面的 `xcodebuild ... test -only-testing:CuteStickerCameraTests/DoodleTests`
Expected: 编译失败，报 `cannot find 'DoodlePalette' in scope`

- [ ] **Step 4: 写实现**

创建 `CuteStickerCamera/Core/DoodleTool.swift`：

```swift
import CoreGraphics
import Foundation

public struct DoodleColor: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat

    public init(id: String, title: String, red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.id = id
        self.title = title
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum DoodlePalette {
    public static let all: [DoodleColor] = [
        DoodleColor(id: "strawberry", title: "草莓红", red: 0.95, green: 0.30, blue: 0.36),
        DoodleColor(id: "tangerine", title: "蜜橘橙", red: 1.00, green: 0.60, blue: 0.25),
        DoodleColor(id: "lemon", title: "柠檬黄", red: 1.00, green: 0.85, blue: 0.30),
        DoodleColor(id: "grass", title: "青草绿", red: 0.45, green: 0.80, blue: 0.45),
        DoodleColor(id: "sky", title: "天空蓝", red: 0.35, green: 0.68, blue: 0.95),
        DoodleColor(id: "grape", title: "葡萄紫", red: 0.66, green: 0.50, blue: 0.90),
        DoodleColor(id: "bubble", title: "泡泡粉", red: 1.00, green: 0.62, blue: 0.78),
        DoodleColor(id: "cream", title: "奶油白", red: 1.00, green: 1.00, blue: 1.00)
    ]

    public static let defaultColor = all[6]
}

public enum DoodleBrushWidth: String, CaseIterable, Identifiable, Sendable {
    case thin
    case medium
    case thick

    public var id: String { rawValue }

    public var pointSize: CGFloat {
        switch self {
        case .thin: 6
        case .medium: 14
        case .thick: 26
        }
    }

    public var title: String {
        switch self {
        case .thin: "细"
        case .medium: "中"
        case .thick: "粗"
        }
    }
}

public struct DoodleToolState: Equatable, Sendable {
    public var color: DoodleColor
    public var width: DoodleBrushWidth
    /// 橡皮只是临时切换，颜色和粗细要留着，切回来还是原来的笔。
    public var isErasing: Bool

    public init(
        color: DoodleColor = DoodlePalette.defaultColor,
        width: DoodleBrushWidth = .medium,
        isErasing: Bool = false
    ) {
        self.color = color
        self.width = width
        self.isErasing = isErasing
    }
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/DoodleTests`
Expected: 4 个用例全部 PASS

- [ ] **Step 6: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/DoodleTool.swift CuteStickerCameraTests/Core/DoodleTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(涂鸦): 添加画笔颜色与粗细模型"
```

---

### Task 2: 涂鸦画布

**Files:**
- Create: `CuteStickerCamera/Views/DoodleCanvasView.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

- [ ] **Step 1: 写画布封装**

创建 `CuteStickerCamera/Views/DoodleCanvasView.swift`：

```swift
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
        isErasing
            ? PKEraserTool(.bitmap, width: width.pointSize * 1.6)
            : PKInkingTool(.pen, color: uiColor, width: width.pointSize)
    }
}
```

- [ ] **Step 2: 登记并编译**

```sh
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj DoodleCanvasView.swift B041 F043 GlassControls.swift B039 F041
```

Run: `xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' build CODE_SIGNING_ALLOWED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/DoodleCanvasView.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(涂鸦): 添加手指绘制画布"
```

---

### Task 3: 涂鸦工具条

**Files:**
- Create: `CuteStickerCamera/Views/DoodleToolbar.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

- [ ] **Step 1: 写工具条**

创建 `CuteStickerCamera/Views/DoodleToolbar.swift`：

```swift
import SwiftUI

struct DoodleToolbar: View {
    @Binding var tool: DoodleToolState
    let onUndo: () -> Void
    let onClear: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            colorRow
            actionRow
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26))
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(DoodlePalette.all) { item in
                Button {
                    tool.color = item
                    tool.isErasing = false
                } label: {
                    Circle()
                        .fill(Color(red: item.red, green: item.green, blue: item.blue))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(.white, lineWidth: isPicked(item) ? 3 : 1)
                        )
                        .scaleEffect(isPicked(item) ? 1.18 : 1)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .accessibilityLabel("画笔颜色：\(item.title)")
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 14) {
            ForEach(DoodleBrushWidth.allCases) { item in
                Button {
                    tool.width = item
                    tool.isErasing = false
                } label: {
                    Circle()
                        .fill(tool.width == item && !tool.isErasing ? Color.pink : Color.white.opacity(0.85))
                        .frame(width: item.pointSize * 0.9 + 8, height: item.pointSize * 0.9 + 8)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .accessibilityLabel("画笔粗细：\(item.title)")
            }

            actionButton(systemImage: "eraser.fill", isActive: tool.isErasing) {
                tool.isErasing.toggle()
            }
            .accessibilityLabel(tool.isErasing ? "切回画笔" : "使用橡皮")

            actionButton(systemImage: "arrow.uturn.backward", isActive: false, action: onUndo)
                .accessibilityLabel("撤销一笔")

            actionButton(systemImage: "trash.fill", isActive: false, action: onClear)
                .accessibilityLabel("清空涂鸦")

            Button(action: onDone) {
                Text("完成")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.pink, in: Capsule())
            }
            .accessibilityLabel("退出涂鸦")
        }
    }

    private func actionButton(systemImage: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(isActive ? .white : .purple)
                .frame(width: 44, height: 44)
                .background(isActive ? Color.pink : Color.white.opacity(0.85), in: Circle())
        }
    }

    private func isPicked(_ item: DoodleColor) -> Bool {
        tool.color == item && !tool.isErasing
    }
}
```

- [ ] **Step 2: 登记并编译**

```sh
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj DoodleToolbar.swift B042 F044 DoodleCanvasView.swift B041 F043
```

Run: `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/DoodleToolbar.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(涂鸦): 添加颜色与粗细工具条"
```

---

### Task 4: 成片合成涂鸦

**Files:**
- Modify: `CuteStickerCamera/Services/PhotoComposer.swift`
- Modify: `CuteStickerCameraTests/Core/DoodleTests.swift`

- [ ] **Step 1: 写失败的测试**

在 `DoodleTests.swift` 的最后一个方法之后、类的右大括号之前插入：

```swift
#if canImport(UIKit)
    func testComposerDrawsDoodleAboveStickersAndBelowFrame() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        func solid(_ color: UIColor, _ size: CGSize) -> UIImage {
            UIGraphicsImageRenderer(size: size, format: format).image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }

        let preview = CGSize(width: 400, height: 800)
        let result = try PhotoComposer().compose(
            image: solid(.blue, CGSize(width: 400, height: 800)),
            previewSize: preview,
            layers: [],
            doodle: solid(.red, preview)
        )

        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            UIGraphicsPushContext(context)
            result.draw(at: CGPoint(x: -200, y: -400))
            UIGraphicsPopContext()
        }

        XCTAssertEqual(Array(bytes.prefix(3)), [255, 0, 0], "涂鸦没有盖在底图上")
    }
#endif
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/DoodleTests`
Expected: 编译失败，报 `extra argument 'doodle' in call`

- [ ] **Step 3: 给合成器加涂鸦参数**

`CuteStickerCamera/Services/PhotoComposer.swift`，把 `compose` 的签名改成：

```swift
    func compose(
        image: UIImage,
        previewSize: CGSize,
        layers: [StickerLayer],
        frameStyle: FrameStyle = .none,
        pictureInPicture: PictureInPicturePhoto? = nil,
        doodle: UIImage? = nil
    ) throws -> UIImage {
```

然后在贴纸循环结束之后、`FrameRenderer.draw` 之前插入：

```swift
            // 涂鸦压在贴纸上，但要留在边框下面。
            if let doodle {
                doodle.draw(in: CGRect(origin: .zero, size: canvas.size))
            }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/DoodleTests`
Expected: 5 个用例全部 PASS

- [ ] **Step 5: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Services/PhotoComposer.swift CuteStickerCameraTests/Core/DoodleTests.swift
git commit -m "feat(涂鸦): 成片合成涂鸦图层"
```

---

### Task 5: 接入相机界面

**Files:**
- Modify: `CuteStickerCamera/Core/CameraControlGrouping.swift`
- Modify: `CuteStickerCamera/Views/CameraScreen.swift`
- Modify: `CuteStickerCameraTests/Core/StickerCanvasTests.swift`

- [ ] **Step 1: 改快捷键测试（会先失败）**

把 `StickerCanvasTests.swift` 里 `testCameraControlsKeepStickersFramesAndCollageAsQuickActions` 的第一行断言换成：

```swift
        XCTAssertEqual(CameraControlGrouping.quickActions, [.stickers, .frames, .collage, .doodle])
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/StickerCanvasTests/testCameraControlsKeepStickersFramesAndCollageAsQuickActions`
Expected: 编译失败，报 `type 'CameraControlAction' has no member 'doodle'`

- [ ] **Step 3: 加动作枚举**

`CuteStickerCamera/Core/CameraControlGrouping.swift`，在 `case collage` 之后加一行：

```swift
    case doodle
```

并把快捷键改成：

```swift
    static let quickActions: [CameraControlAction] = [.stickers, .frames, .collage, .doodle]
```

- [ ] **Step 4: 跑测试确认通过**

Run: 同 Step 2
Expected: PASS

- [ ] **Step 5: 给 CameraScreen 加状态**

在 `CameraScreen` 的属性区（`collageOverlayLayout` 那行之后）加入：

```swift
    @State private var isDoodling = false
    @State private var doodleTool = DoodleToolState()
    @State private var doodleDrawing = PKDrawing()
```

并在文件顶部的 `import UIKit` 之后加入：

```swift
import PencilKit
```

- [ ] **Step 6: 插入涂鸦图层**

在 `StickerCanvasView(...)` 那一段之后、`FrameOverlayView(style: frameStyle)` 之前插入：

```swift
                DoodleCanvasView(drawing: $doodleDrawing, tool: doodleTool, isActive: isDoodling)
                    .frame(width: contentRect.width, height: contentRect.height)
                    .position(x: contentRect.midX, y: contentRect.midY)
                    .allowsHitTesting(isDoodling)
```

- [ ] **Step 7: 涂鸦时锁住贴纸**

把 `StickerCanvasView` 那段的 `.allowsHitTesting(...)` 改成：

```swift
                    .allowsHitTesting(camera.permissionState.allowsStickerEditing && !isDoodling)
```

- [ ] **Step 8: 加入口按钮**

在 `quickActionButton(for:)` 的 `case .collage` 之后插入：

```swift
        case .doodle:
            quickCircleButton(systemImage: "scribble.variable", isActive: isDoodling) {
                isDoodling.toggle()
            }
            .accessibilityLabel(isDoodling ? "退出涂鸦" : "开始涂鸦")
```

- [ ] **Step 9: 显示工具条**

在 `sideQuickActions(bottomInset: proxy.safeAreaInsets.bottom)` 那一行之后插入：

```swift
                if isDoodling {
                    VStack {
                        Spacer()
                        DoodleToolbar(
                            tool: $doodleTool,
                            onUndo: { undoDoodle() },
                            onClear: { clearDoodle() },
                            onDone: { isDoodling = false }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 118 + proxy.safeAreaInsets.bottom)
                    }
                }
```

- [ ] **Step 10: 写撤销、清空与导出**

先在属性区补一个状态（放在 `doodleDrawing` 那行之后）：

```swift
    @State private var clearedDoodle: PKDrawing?
```

再在 `cancelCollage()` 方法之后插入：

```swift
    /// 撤销优先恢复刚被清空的整幅，其次才回退最后一笔。
    private func undoDoodle() {
        if let clearedDoodle {
            doodleDrawing = clearedDoodle
            self.clearedDoodle = nil
            return
        }
        guard !doodleDrawing.strokes.isEmpty else { return }
        var strokes = doodleDrawing.strokes
        strokes.removeLast()
        doodleDrawing = PKDrawing(strokes: strokes)
    }

    private func clearDoodle() {
        guard !doodleDrawing.strokes.isEmpty else { return }
        clearedDoodle = doodleDrawing
        doodleDrawing = PKDrawing()
    }

    /// 预览是点、成片是像素，4 倍足够覆盖当前机型的照片分辨率。
    private func doodleImage(previewSize: CGSize) -> UIImage? {
        guard !doodleDrawing.strokes.isEmpty else { return nil }
        return doodleDrawing.image(from: CGRect(origin: .zero, size: previewSize), scale: 4)
    }
```

- [ ] **Step 10b: 新笔画作废掉“撤销清空”**

清空后如果又画了新笔，就不该再跳回清空前的状态。在 `DoodleCanvasView` 那段之后追加一个监听：

```swift
                    .onChange(of: doodleDrawing.strokes.count) { count in
                        if count > 0 { clearedDoodle = nil }
                    }
```

- [ ] **Step 11: 合成时带上涂鸦**

`saveComposed` 里把 `PhotoComposer().compose(...)` 的调用改成带 doodle 参数。先在 `Task.detached` 之前取出图：

```swift
        let doodle = doodleImage(previewSize: previewSize)
```

再把合成调用改成：

```swift
                let result = try PhotoComposer().compose(image: image, previewSize: previewSize, layers: layers, frameStyle: frameStyle, pictureInPicture: pip, doodle: doodle)
```

`handleCollageShot` 里同样处理：在 `Task.detached` 之前加 `let doodle = doodleImage(previewSize: previewSize)`，并把 compose 调用补上 `doodle: doodle`。

- [ ] **Step 12: 涂鸦时锁画幅**

`expandedSettingsButton(for:)` 里 `case .aspectRatio` 的 `.disabled(collageSession != nil)` 改成：

```swift
            .disabled(collageSession != nil || isDoodling)
```

- [ ] **Step 13: 跑全量测试**

Run: 完整的 `xcodebuild ... test` 命令
Expected: 新增用例全部 PASS，除了本计划开头提到的 4 个 codex 遗留失败，没有其他红色

- [ ] **Step 14: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/CameraControlGrouping.swift CuteStickerCamera/Views/CameraScreen.swift CuteStickerCameraTests/Core/StickerCanvasTests.swift
git commit -m "feat(涂鸦): 接入相机界面与成片合成"
```

---

### Task 6: 验收

**Files:**
- Create: `docs/verification/2026-09-24-doodle-layer.md`

- [ ] **Step 1: 模拟器回归**

Run: 完整的 `xcodebuild ... test` 命令
记录用例总数与失败数，确认失败项仅为 codex 遗留的那 4 个。

- [ ] **Step 2: 模拟器目视**

临时把 `isDoodling` 初值改成 `true` 编译安装，截图确认：

- 右侧快捷键变成四个，画笔图标为高亮态。
- 工具条两行完整显示，8 个颜色、3 档粗细、橡皮、撤销、清空、完成都在，没有被快门遮挡。
- 截完把初值改回 `false`。

- [ ] **Step 3: 真机验收**

- 手指能画出线，笔画跟手不断。
- 切换 8 个颜色和 3 档粗细，画出来的笔画符合预期。
- 橡皮能擦掉笔画，擦完切回画笔颜色粗细不变。
- 撤销能一笔笔退，清空能全清。
- 涂鸦模式下贴纸拖不动，点「完成」退出后贴纸恢复可拖。
- 涂鸦模式下画幅按钮为禁用态。
- 拍一张，在系统照片里确认涂鸦位置与预览一致，且边框压在涂鸦之上。
- 大头贴模式下拍一轮，确认每格都带涂鸦。
- 切后台再回来，涂鸦还在。

- [ ] **Step 4: 写验证记录**

创建 `docs/verification/2026-09-24-doodle-layer.md`，按 `docs/verification/2026-09-23-photo-booth-collage.md` 的结构记录：已执行项、测试命令与结果、尚未完成的真机验收项、环境说明。

- [ ] **Step 5: 提交（先征得用户许可）**

```bash
git add docs/verification/2026-09-24-doodle-layer.md
git commit -m "chore(涂鸦): 添加验收记录"
```
