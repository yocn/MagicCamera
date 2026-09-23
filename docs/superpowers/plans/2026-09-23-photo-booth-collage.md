# 大头贴拼贴 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让贴纸相机支持大头贴模式：选定排版、花边和拍法后连续拍摄，自动合成一张多格拼贴照片保存到系统照片。

**Architecture:** 排版、花边、拍摄状态机作为无 UIKit 依赖的纯逻辑放进 `Core/`，可被 SPM 的 `CuteStickerCore` target 编译和单测。单格成图继续走现有 `PhotoComposer`，新增的 `CollageComposer` 只负责把成品按格子排版并绘制花边。`CameraScreen` 增加大头贴模式状态，拦截拍照回调驱动状态机。

**Tech Stack:** Swift 5、SwiftUI、UIKit、CoreGraphics、XCTest。

**Spec:** `docs/superpowers/specs/2026-09-23-photo-booth-collage-design.md`

## Global Constraints

- 最低部署版本 iOS 16.0，不引入第三方依赖。
- `Core/` 下的新文件只能 import `Foundation` / `CoreGraphics`，不得 import UIKit，否则 SPM target 编译失败。
- 注释一行为限，只写非显而易见的约束，不写方案权衡。
- commit message 格式 `<type>(<scope>): <中文描述>`，只有标题行，不加 `Co-Authored-By`。
- **每一次 commit 前必须向用户显式请求许可**，得到明确同意才执行（用户全局规范，覆盖本计划里的 commit 步骤）。
- 新增源文件必须同步登记进 `CuteStickerCamera.xcodeproj/project.pbxproj`，否则不参与编译。

## 工程文件登记约定

`project.pbxproj` 用的是短 ID。每个新文件需要改 4 处：`PBXBuildFile`（约 36-40 行区）、`PBXFileReference`（约 118-122 行区）、所属 `PBXGroup` 的 children、app target 的 `PBXSourcesBuildPhase`（约 499-506 行区）。本计划预分配的 ID：

| 文件 | BuildFile | FileRef | Group |
| --- | --- | --- | --- |
| `Core/CollageLayout.swift` | B027 | F029 | P104 Core |
| `Core/CollageStyle.swift` | B028 | F030 | P104 Core |
| `Core/CollageSession.swift` | B029 | F031 | P104 Core |
| `Services/ImageCropping.swift` | B030 | F032 | P105 Services |
| `Services/CollageComposer.swift` | B031 | F033 | P105 Services |
| `Services/CollageDecorationRenderer.swift` | B032 | F034 | P105 Services |
| `Views/CollageGridView.swift` | B033 | F035 | P106 Views |
| `Views/CollageProgressView.swift` | B034 | F036 | P106 Views |
| `Views/CollageTrayView.swift` | B035 | F037 | P106 Views |
| `CuteStickerCameraTests/Core/CollageTests.swift` | B203 | F203 | 测试 group，登记到 P201S |

## 测试命令

```sh
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera \
  -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

只跑单个用例时追加 `-only-testing:CuteStickerCameraTests/CollageTests/<方法名>`。

---

### Task 1: 排版模型

**Files:**
- Create: `CuteStickerCamera/Core/CollageLayout.swift`
- Create: `CuteStickerCameraTests/Core/CollageTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

- [ ] **Step 1: 先把测试文件登记进工程**

在 `project.pbxproj` 的 PBXBuildFile 段（`B202` 那行之后）加入：

```
		B203 /* CollageTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = F203 /* CollageTests.swift */; };
```

在 PBXFileReference 段（`F202` 那行之后）加入：

```
		F203 /* CollageTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CollageTests.swift; sourceTree = "<group>"; };
```

在测试 group 的 children（`F202 /* StickerRenderTransformTests.swift */,` 之后）加入：

```
				F203 /* CollageTests.swift */,
```

在 `P201S /* Sources */` 的 files（`B202 ... in Sources */,` 之后）加入：

```
				B203 /* CollageTests.swift in Sources */,
```

同样把 `CollageLayout.swift` 按上表登记（B027 / F029 / P104 Core group / app target Sources）。

- [ ] **Step 2: 写失败的测试**

创建 `CuteStickerCameraTests/Core/CollageTests.swift`：

```swift
import CoreGraphics
import XCTest
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class CollageTests: XCTestCase {
    func testEveryCollageLayoutTilesTheWholeCanvasWithoutOverlap() {
        for layout in CollageLayout.allCases {
            let cells = layout.cells
            XCTAssertEqual(cells.count, layout.shotCount, "\(layout.title) 的格数与 shotCount 不一致")

            let area = cells.reduce(CGFloat.zero) { $0 + $1.width * $1.height }
            XCTAssertEqual(area, 1, accuracy: 0.0001, "\(layout.title) 没有铺满画布")

            let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
            for cell in cells {
                XCTAssertTrue(unit.contains(cell), "\(layout.title) 的格子越界")
            }

            for (index, cell) in cells.enumerated() {
                for other in cells.dropFirst(index + 1) {
                    XCTAssertFalse(cell.intersects(other), "\(layout.title) 的格子重叠")
                }
            }
        }
    }

    func testVerticalFourProducesTallCanvasWithFourThreeCells() {
        let layout = CollageLayout.verticalFour
        let canvas = layout.canvasSize(width: 1440)

        XCTAssertEqual(canvas.width, 1440, accuracy: 0.5)
        XCTAssertEqual(canvas.height, 4320, accuracy: 0.5)

        for cell in layout.cells {
            let ratio = (cell.width * canvas.width) / (cell.height * canvas.height)
            XCTAssertEqual(ratio, 4.0 / 3.0, accuracy: 0.001)
        }
    }

    func testSquareLayoutsKeepSquareCanvasAndFourGridIsDefault() {
        for layout in [CollageLayout.fourGrid, .twoOverOne, .oneOverTwo, .bigLeft, .nineGrid] {
            XCTAssertEqual(layout.aspectRatio, 1, accuracy: 0.0001, "\(layout.title) 画布不是正方形")
        }
        XCTAssertEqual(CollageLayout.fourGrid.shotCount, 4)
        XCTAssertEqual(CollageLayout.nineGrid.shotCount, 9)
        XCTAssertEqual(CollageLayout.twoRows.shotCount, 2)
    }
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: 上面的 `xcodebuild ... test` 命令
Expected: 编译失败，报 `cannot find 'CollageLayout' in scope`

- [ ] **Step 4: 写实现**

创建 `CuteStickerCamera/Core/CollageLayout.swift`：

```swift
import CoreGraphics
import Foundation

public enum CollageLayout: String, CaseIterable, Identifiable, Sendable {
    case fourGrid
    case twoOverOne
    case oneOverTwo
    case verticalFour
    case verticalThree
    case bigLeft
    case twoRows
    case sixGrid
    case nineGrid

    /// 合成画布宽度，高度由 aspectRatio 推出。
    public static let canvasWidth: CGFloat = 1440

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fourGrid: "四宫格"
        case .twoOverOne: "上二下一"
        case .oneOverTwo: "上一下二"
        case .verticalFour: "竖排四格"
        case .verticalThree: "竖排三格"
        case .bigLeft: "左大右二"
        case .twoRows: "上下二格"
        case .sixGrid: "六宫格"
        case .nineGrid: "九宫格"
        }
    }

    /// 画布宽 ÷ 画布高。
    public var aspectRatio: CGFloat {
        switch self {
        case .fourGrid, .twoOverOne, .oneOverTwo, .bigLeft, .nineGrid: 1
        case .verticalFour: 1.0 / 3.0
        case .verticalThree: 1.0 / 2.25
        case .twoRows, .sixGrid: 1.0 / 1.5
        }
    }

    public var cells: [CGRect] {
        switch self {
        case .fourGrid:
            Self.grid(columns: 2, rows: 2)
        case .twoOverOne:
            [
                CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
                CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
                CGRect(x: 0, y: 0.5, width: 1, height: 0.5)
            ]
        case .oneOverTwo:
            [
                CGRect(x: 0, y: 0, width: 1, height: 0.5),
                CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
                CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
            ]
        case .verticalFour:
            Self.grid(columns: 1, rows: 4)
        case .verticalThree:
            Self.grid(columns: 1, rows: 3)
        case .bigLeft:
            [
                CGRect(x: 0, y: 0, width: 0.62, height: 1),
                CGRect(x: 0.62, y: 0, width: 0.38, height: 0.5),
                CGRect(x: 0.62, y: 0.5, width: 0.38, height: 0.5)
            ]
        case .twoRows:
            Self.grid(columns: 1, rows: 2)
        case .sixGrid:
            Self.grid(columns: 2, rows: 3)
        case .nineGrid:
            Self.grid(columns: 3, rows: 3)
        }
    }

    public var shotCount: Int { cells.count }

    public func canvasSize(width: CGFloat = CollageLayout.canvasWidth) -> CGSize {
        CGSize(width: width, height: width / aspectRatio)
    }

    private static func grid(columns: Int, rows: Int) -> [CGRect] {
        let width = 1 / CGFloat(columns)
        let height = 1 / CGFloat(rows)
        return (0..<rows).flatMap { row in
            (0..<columns).map { column in
                CGRect(
                    x: CGFloat(column) * width,
                    y: CGFloat(row) * height,
                    width: width,
                    height: height
                )
            }
        }
    }
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 3 个用例全部 PASS

- [ ] **Step 6: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/CollageLayout.swift CuteStickerCameraTests/Core/CollageTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加拼贴排版模型"
```

---

### Task 2: 花边模型

**Files:**
- Create: `CuteStickerCamera/Core/CollageStyle.swift`
- Modify: `CuteStickerCameraTests/Core/CollageTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B028 / F030）

- [ ] **Step 1: 写失败的测试**

在 `CollageTests.swift` 的 `testSquareLayoutsKeepSquareCanvasAndFourGridIsDefault` 之后插入：

```swift
    func testCollageStyleMetricsStayWithinSafeRanges() {
        for style in CollageStyle.allCases {
            let metrics = style.metrics
            XCTAssertTrue((0...0.1).contains(metrics.outerMargin), "\(style.title) 外边距超范围")
            XCTAssertTrue((0...0.05).contains(metrics.gutter), "\(style.title) 格缝超范围")
            XCTAssertTrue((0...0.2).contains(metrics.cornerRadius), "\(style.title) 圆角超范围")
        }
    }

    func testPlainCollageStyleDrawsNothingExtra() {
        let metrics = CollageStyle.plain.metrics

        XCTAssertEqual(metrics.outerMargin, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.gutter, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.cornerRadius, 0, accuracy: 0.0001)
        XCTAssertEqual(metrics.decoration, .none)
        XCTAssertEqual(metrics.background.alpha, 0, accuracy: 0.0001)
    }

    func testDecoratedCollageStylesReserveMarginForTheirOrnament() {
        for style in [CollageStyle.wave, .rainbow, .stars] {
            XCTAssertNotEqual(style.metrics.decoration, .none, "\(style.title) 缺少装饰")
            XCTAssertGreaterThan(style.metrics.outerMargin, 0, "\(style.title) 没有给装饰留出外边距")
        }
    }
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 编译失败，报 `cannot find 'CollageStyle' in scope`

- [ ] **Step 3: 写实现**

创建 `CuteStickerCamera/Core/CollageStyle.swift`：

```swift
import CoreGraphics
import Foundation

public enum CollageDecoration: String, Equatable, Sendable {
    case none
    case wave
    case rainbow
    case stars
}

/// Core target 不依赖 UIKit，颜色以分量形式传递。
public struct CollageBackground: Equatable, Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let clear = CollageBackground(red: 0, green: 0, blue: 0, alpha: 0)
    public static let white = CollageBackground(red: 1, green: 1, blue: 1, alpha: 1)
    public static let cream = CollageBackground(red: 1, green: 0.965, blue: 0.914, alpha: 1)
    public static let blush = CollageBackground(red: 1, green: 0.914, blue: 0.949, alpha: 1)
}

public struct CollageStyleMetrics: Equatable, Sendable {
    /// 画布宽度比例。
    public let outerMargin: CGFloat
    /// 画布宽度比例。
    public let gutter: CGFloat
    /// 格子短边比例。
    public let cornerRadius: CGFloat
    public let background: CollageBackground
    public let decoration: CollageDecoration

    public init(
        outerMargin: CGFloat,
        gutter: CGFloat,
        cornerRadius: CGFloat,
        background: CollageBackground,
        decoration: CollageDecoration
    ) {
        self.outerMargin = outerMargin
        self.gutter = gutter
        self.cornerRadius = cornerRadius
        self.background = background
        self.decoration = decoration
    }
}

public enum CollageStyle: String, CaseIterable, Identifiable, Sendable {
    case plain
    case classicWhite
    case cream
    case wave
    case rainbow
    case stars

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .plain: "无边"
        case .classicWhite: "经典白边"
        case .cream: "奶油圆角"
        case .wave: "波浪花边"
        case .rainbow: "彩虹条"
        case .stars: "星星点点"
        }
    }

    public var iconName: String {
        switch self {
        case .plain: "square"
        case .classicWhite: "square.inset.filled"
        case .cream: "square.on.square"
        case .wave: "water.waves"
        case .rainbow: "rainbow"
        case .stars: "sparkles"
        }
    }

    public var metrics: CollageStyleMetrics {
        switch self {
        case .plain:
            CollageStyleMetrics(outerMargin: 0, gutter: 0, cornerRadius: 0, background: .clear, decoration: .none)
        case .classicWhite:
            CollageStyleMetrics(outerMargin: 0.035, gutter: 0.025, cornerRadius: 0, background: .white, decoration: .none)
        case .cream:
            CollageStyleMetrics(outerMargin: 0.04, gutter: 0.03, cornerRadius: 0.08, background: .cream, decoration: .none)
        case .wave:
            CollageStyleMetrics(outerMargin: 0.05, gutter: 0.03, cornerRadius: 0.06, background: .white, decoration: .wave)
        case .rainbow:
            CollageStyleMetrics(outerMargin: 0.045, gutter: 0.028, cornerRadius: 0.05, background: .white, decoration: .rainbow)
        case .stars:
            CollageStyleMetrics(outerMargin: 0.045, gutter: 0.03, cornerRadius: 0.07, background: .blush, decoration: .stars)
        }
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 6 个用例全部 PASS

- [ ] **Step 5: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/CollageStyle.swift CuteStickerCameraTests/Core/CollageTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加拼贴花边样式"
```

---

### Task 3: 拍摄状态机

**Files:**
- Create: `CuteStickerCamera/Core/CollageSession.swift`
- Modify: `CuteStickerCameraTests/Core/CollageTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B029 / F031）

- [ ] **Step 1: 写失败的测试**

在 `CollageTests.swift` 里追加：

```swift
    func testCollageSessionAdvancesUntilTheLayoutIsFull() {
        var session = CollageSession(layout: .fourGrid, style: .classicWhite, mode: .burstThree)

        XCTAssertEqual(session.remaining, 4)
        XCTAssertEqual(session.currentIndex, 0)
        XCTAssertFalse(session.isComplete)

        session.advance()
        XCTAssertEqual(session.currentIndex, 1)
        XCTAssertEqual(session.remaining, 3)

        for _ in 0..<3 { session.advance() }
        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.remaining, 0)
    }

    func testCompletedCollageSessionIgnoresExtraShots() {
        var session = CollageSession(layout: .twoRows, style: .plain, mode: .manual)

        session.advance()
        session.advance()
        session.advance()

        XCTAssertEqual(session.capturedCount, 2)
        XCTAssertTrue(session.isComplete)
    }

    func testBurstModesCarryCountdownAndManualDoesNot() {
        XCTAssertEqual(CollageCaptureMode.burstThree.countdownSeconds, 3)
        XCTAssertEqual(CollageCaptureMode.burstFive.countdownSeconds, 5)
        XCTAssertNil(CollageCaptureMode.manual.countdownSeconds)

        XCTAssertTrue(CollageCaptureMode.burstThree.isBurst)
        XCTAssertTrue(CollageCaptureMode.burstFive.isBurst)
        XCTAssertFalse(CollageCaptureMode.manual.isBurst)

        XCTAssertEqual(CollageCaptureTiming.shotInterval, 0.8, accuracy: 0.0001)
    }
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 编译失败，报 `cannot find 'CollageSession' in scope`

- [ ] **Step 3: 写实现**

创建 `CuteStickerCamera/Core/CollageSession.swift`：

```swift
import Foundation

public enum CollageCaptureMode: String, CaseIterable, Identifiable, Sendable {
    case burstThree
    case burstFive
    case manual

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .burstThree: "连拍 3 秒"
        case .burstFive: "连拍 5 秒"
        case .manual: "逐格手动"
        }
    }

    public var iconName: String {
        switch self {
        case .burstThree, .burstFive: "timer"
        case .manual: "hand.tap.fill"
        }
    }

    public var countdownSeconds: Int? {
        switch self {
        case .burstThree: 3
        case .burstFive: 5
        case .manual: nil
        }
    }

    public var isBurst: Bool { countdownSeconds != nil }
}

public enum CollageCaptureTiming {
    /// 两格之间的缓冲，留给上一格的快门效果播完。
    public static let shotInterval: TimeInterval = 0.8
}

public struct CollageSession: Equatable, Sendable {
    public let layout: CollageLayout
    public let style: CollageStyle
    public let mode: CollageCaptureMode
    public private(set) var capturedCount: Int

    public init(layout: CollageLayout, style: CollageStyle, mode: CollageCaptureMode) {
        self.layout = layout
        self.style = style
        self.mode = mode
        self.capturedCount = 0
    }

    public var currentIndex: Int { min(capturedCount, layout.shotCount - 1) }

    public var remaining: Int { max(0, layout.shotCount - capturedCount) }

    public var isComplete: Bool { capturedCount >= layout.shotCount }

    public mutating func advance() {
        guard !isComplete else { return }
        capturedCount += 1
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 9 个用例全部 PASS

- [ ] **Step 5: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/CollageSession.swift CuteStickerCameraTests/Core/CollageTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加拍摄状态机"
```

---

### Task 4: 提取图片裁剪扩展

`CollageComposer` 需要和 `PhotoComposer` 用同一套居中裁剪，先把现有的私有扩展提出来。这是纯重构，行为不变。

**Files:**
- Create: `CuteStickerCamera/Services/ImageCropping.swift`
- Modify: `CuteStickerCamera/Services/PhotoComposer.swift:59-87`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B030 / F032）

- [ ] **Step 1: 建立新文件**

创建 `CuteStickerCamera/Services/ImageCropping.swift`，内容就是从 `PhotoComposer.swift` 末尾原样搬来的两个扩展，去掉 `private`：

```swift
import UIKit

extension UIImage {
    func normalized() -> UIImage? {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    func centerCropped(toAspect aspect: CGFloat) -> UIImage {
        let currentAspect = size.width / size.height
        let cropSize: CGSize
        if currentAspect > aspect {
            cropSize = CGSize(width: size.height * aspect, height: size.height)
        } else {
            cropSize = CGSize(width: size.width, height: size.width / aspect)
        }
        let crop = CGRect(
            x: (size.width - cropSize.width) / 2,
            y: (size.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        )
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        return renderer.image { _ in draw(in: CGRect(origin: crop.origin.negated, size: size)) }
    }
}

extension CGPoint {
    var negated: CGPoint { CGPoint(x: -x, y: -y) }
}
```

- [ ] **Step 2: 从 PhotoComposer 删掉搬走的代码**

删除 `CuteStickerCamera/Services/PhotoComposer.swift` 第 59 行到文件末尾的两个 `private extension`，文件以 `compose` 方法的结束大括号收尾。

- [ ] **Step 3: 登记进工程并编译**

按 ID 表把 `ImageCropping.swift` 登记进 `project.pbxproj`（B030 / F032 / P105 Services / app target Sources）。

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/StickerRenderTransformTests`
Expected: 全部 PASS，尤其 `testPictureInPictureCompositionIncludesFrontImageAndRoundedCorners` 仍然通过，证明裁剪行为没变

- [ ] **Step 4: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Services/ImageCropping.swift CuteStickerCamera/Services/PhotoComposer.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "refactor(照片合成): 提取图片居中裁剪扩展"
```

---

### Task 5: 拼贴合成

**Files:**
- Create: `CuteStickerCamera/Services/CollageComposer.swift`
- Create: `CuteStickerCamera/Services/CollageDecorationRenderer.swift`
- Modify: `CuteStickerCameraTests/Core/CollageTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B031 / F033、B032 / F034）

- [ ] **Step 1: 写失败的测试**

在 `CollageTests.swift` 里追加（注意要放进 `#if canImport(UIKit)` 块，文件里目前没有这个块，直接把下面整段连同条件编译一起加在最后一个方法之后）：

```swift
#if canImport(UIKit)
    func testCollageComposerFillsEveryCellWithItsOwnShot() throws {
        let colors: [UIColor] = [.red, .green, .blue, .yellow]
        let shots = colors.map { solidImage($0, CGSize(width: 300, height: 300)) }

        let result = try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .plain)

        let canvas = CollageLayout.fourGrid.canvasSize()
        XCTAssertEqual(result.size.width, canvas.width, accuracy: 1)
        XCTAssertEqual(result.size.height, canvas.height, accuracy: 1)

        let expected: [[UInt8]] = [[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0]]
        for (index, cell) in CollageLayout.fourGrid.cells.enumerated() {
            let x = cell.midX * result.size.width
            let y = cell.midY * result.size.height
            XCTAssertEqual(rgb(of: result, x: x, y: y), expected[index], "第 \(index + 1) 格取到的颜色不对")
        }
    }

    func testCollageComposerRejectsWrongShotCount() {
        let shots = [solidImage(.red, CGSize(width: 100, height: 100))]

        XCTAssertThrowsError(try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .plain))
    }

    func testClassicWhiteStyleLeavesWhiteMarginAroundTheGrid() throws {
        let shots = (0..<4).map { _ in solidImage(.black, CGSize(width: 300, height: 300)) }

        let result = try CollageComposer().compose(shots: shots, layout: .fourGrid, style: .classicWhite)

        XCTAssertEqual(rgb(of: result, x: 4, y: 4), [255, 255, 255], "外边距没有留白")
        let center = CGPoint(x: result.size.width / 2, y: result.size.height / 2)
        XCTAssertEqual(rgb(of: result, x: center.x, y: center.y), [255, 255, 255], "格缝没有留白")
    }

    private func solidImage(_ color: UIColor, _ size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func rgb(of image: UIImage, x: CGFloat, y: CGFloat) -> [UInt8] {
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
            image.draw(at: CGPoint(x: -x, y: -y))
            UIGraphicsPopContext()
        }
        return Array(bytes.prefix(3))
    }
#endif
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 编译失败，报 `cannot find 'CollageComposer' in scope`

- [ ] **Step 3: 写装饰绘制**

创建 `CuteStickerCamera/Services/CollageDecorationRenderer.swift`：

```swift
import UIKit

enum CollageDecorationRenderer {
    static func draw(_ decoration: CollageDecoration, in rect: CGRect, margin: CGFloat, context: CGContext) {
        guard margin > 0 else { return }
        switch decoration {
        case .none: break
        case .wave: drawWave(in: rect, margin: margin, context: context)
        case .rainbow: drawRainbow(in: rect, margin: margin, context: context)
        case .stars: drawStars(in: rect, margin: margin, context: context)
        }
    }

    /// 半圆骑在内容边缘上，一半压住照片形成扇贝花边。
    private static func drawWave(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let radius = margin * 0.7
        let content = rect.insetBy(dx: margin, dy: margin)
        let path = UIBezierPath()

        var x = content.minX
        while x < content.maxX {
            path.append(UIBezierPath(ovalIn: CGRect(x: x, y: content.minY - radius, width: radius * 2, height: radius * 2)))
            path.append(UIBezierPath(ovalIn: CGRect(x: x, y: content.maxY - radius, width: radius * 2, height: radius * 2)))
            x += radius * 2
        }

        var y = content.minY
        while y < content.maxY {
            path.append(UIBezierPath(ovalIn: CGRect(x: content.minX - radius, y: y, width: radius * 2, height: radius * 2)))
            path.append(UIBezierPath(ovalIn: CGRect(x: content.maxX - radius, y: y, width: radius * 2, height: radius * 2)))
            y += radius * 2
        }

        context.saveGState()
        UIColor.white.setFill()
        path.fill()
        context.restoreGState()
    }

    private static func drawRainbow(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let colors: [UIColor] = [
            UIColor(red: 1, green: 0.42, blue: 0.42, alpha: 1),
            UIColor(red: 1, green: 0.72, blue: 0.35, alpha: 1),
            UIColor(red: 1, green: 0.91, blue: 0.42, alpha: 1),
            UIColor(red: 0.53, green: 0.85, blue: 0.60, alpha: 1),
            UIColor(red: 0.47, green: 0.71, blue: 0.96, alpha: 1)
        ]
        let band = margin / CGFloat(colors.count)

        context.saveGState()
        for (index, color) in colors.enumerated() {
            let inset = band * CGFloat(index) + band / 2
            color.setStroke()
            let path = UIBezierPath(rect: rect.insetBy(dx: inset, dy: inset))
            path.lineWidth = band
            path.stroke()
        }
        context.restoreGState()
    }

    private static func drawStars(in rect: CGRect, margin: CGFloat, context: CGContext) {
        let radius = margin * 0.66
        let centers = [
            CGPoint(x: rect.minX + margin / 2, y: rect.minY + margin / 2),
            CGPoint(x: rect.maxX - margin / 2, y: rect.minY + margin / 2),
            CGPoint(x: rect.minX + margin / 2, y: rect.maxY - margin / 2),
            CGPoint(x: rect.maxX - margin / 2, y: rect.maxY - margin / 2)
        ]

        context.saveGState()
        UIColor.white.setFill()
        for center in centers {
            starPath(center: center, radius: radius).fill()
        }
        context.restoreGState()
    }

    private static func starPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let length = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path
    }
}
```

- [ ] **Step 4: 写合成器**

创建 `CuteStickerCamera/Services/CollageComposer.swift`：

```swift
import UIKit

enum CollageComposerError: LocalizedError {
    case shotCountMismatch

    var errorDescription: String? { "大头贴合成失败，请再试一次。" }
}

struct CollageComposer {
    func compose(shots: [UIImage], layout: CollageLayout, style: CollageStyle) throws -> UIImage {
        guard shots.count == layout.shotCount else { throw CollageComposerError.shotCountMismatch }

        let canvas = layout.canvasSize()
        let metrics = style.metrics
        let margin = canvas.width * metrics.outerMargin
        let gutter = canvas.width * metrics.gutter
        let content = CGRect(origin: .zero, size: canvas).insetBy(dx: margin, dy: margin)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        return renderer.image { context in
            if metrics.background.alpha > 0 {
                metrics.background.uiColor.setFill()
                context.fill(CGRect(origin: .zero, size: canvas))
            }

            for (index, cell) in layout.cells.enumerated() {
                let frame = CGRect(
                    x: content.minX + cell.minX * content.width + gutter / 2,
                    y: content.minY + cell.minY * content.height + gutter / 2,
                    width: cell.width * content.width - gutter,
                    height: cell.height * content.height - gutter
                )
                guard frame.width > 0, frame.height > 0 else { continue }

                let radius = min(frame.width, frame.height) * metrics.cornerRadius
                context.cgContext.saveGState()
                UIBezierPath(roundedRect: frame, cornerRadius: radius).addClip()
                shots[index]
                    .centerCropped(toAspect: frame.width / frame.height)
                    .draw(in: frame)
                context.cgContext.restoreGState()
            }

            CollageDecorationRenderer.draw(
                metrics.decoration,
                in: CGRect(origin: .zero, size: canvas),
                margin: margin,
                context: context.cgContext
            )
        }
    }
}

extension CollageBackground {
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}
```

- [ ] **Step 5: 登记进工程并跑测试**

按 ID 表登记两个新文件。

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/CollageTests`
Expected: 12 个用例全部 PASS

- [ ] **Step 6: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Services/CollageComposer.swift CuteStickerCamera/Services/CollageDecorationRenderer.swift CuteStickerCameraTests/Core/CollageTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加拼贴合成与花边绘制"
```

---

### Task 6: 格子视图与拍摄进度

**Files:**
- Create: `CuteStickerCamera/Views/CollageGridView.swift`
- Create: `CuteStickerCamera/Views/CollageProgressView.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B033 / F035、B034 / F036）

这一层是纯展示，逻辑已被 Task 1 和 Task 3 的测试覆盖，这里靠编译加模拟器目视验收。

- [ ] **Step 1: 写格子视图**

创建 `CuteStickerCamera/Views/CollageGridView.swift`：

```swift
import SwiftUI

/// 按排版摆放格子，每格内容由调用方提供。
struct CollageGridView<Content: View>: View {
    let layout: CollageLayout
    let spacing: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(layout.cells.enumerated()), id: \.offset) { index, cell in
                let width = max(0, cell.width * proxy.size.width - spacing)
                let height = max(0, cell.height * proxy.size.height - spacing)
                content(index)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .position(
                        x: (cell.midX) * proxy.size.width,
                        y: (cell.midY) * proxy.size.height
                    )
            }
        }
        .aspectRatio(layout.aspectRatio, contentMode: .fit)
    }
}
```

- [ ] **Step 2: 写进度视图**

创建 `CuteStickerCamera/Views/CollageProgressView.swift`：

```swift
import SwiftUI
import UIKit

struct CollageProgressView: View {
    let layout: CollageLayout
    let thumbnails: [UIImage]
    let currentIndex: Int
    let width: CGFloat
    let onCancel: () -> Void
    @State private var isPulsing = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CollageGridView(layout: layout, spacing: 2, cornerRadius: 3) { index in
                cell(at: index)
            }
            .frame(width: width)
            .padding(5)
            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .accessibilityLabel("取消大头贴拍摄")
        }
        .onAppear { isPulsing = true }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("大头贴进度：已拍 \(thumbnails.count) 张，共 \(layout.shotCount) 张")
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        if index < thumbnails.count {
            Image(uiImage: thumbnails[index])
                .resizable()
                .scaledToFill()
        } else if index == currentIndex {
            Rectangle()
                .fill(.white.opacity(0.28))
                .overlay(Rectangle().stroke(.pink, lineWidth: 2))
                .opacity(isPulsing ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
        } else {
            Rectangle().fill(.white.opacity(0.18))
        }
    }
}
```

- [ ] **Step 3: 登记进工程并编译**

按 ID 表登记两个新文件。

Run: `xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' build CODE_SIGNING_ALLOWED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/CollageGridView.swift CuteStickerCamera/Views/CollageProgressView.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加格子视图与拍摄进度"
```

---

### Task 7: 大头贴面板

**Files:**
- Create: `CuteStickerCamera/Views/CollageTrayView.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`（B035 / F037）

- [ ] **Step 1: 写面板**

创建 `CuteStickerCamera/Views/CollageTrayView.swift`：

```swift
import SwiftUI

struct CollageTrayView: View {
    @Binding var layout: CollageLayout
    @Binding var style: CollageStyle
    @Binding var mode: CollageCaptureMode
    let onStart: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            header
            layoutRow
            styleRow
            modeRow
            startButton
        }
        .padding(.bottom, 16)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        ZStack(alignment: .trailing) {
            Text("大头贴 ✨")
                .font(.headline)
                .foregroundStyle(.purple)
                .frame(maxWidth: .infinity)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.pink, in: Circle())
            }
            .accessibilityLabel("关闭大头贴面板")
        }
        .padding(.horizontal, StickerTrayLayout.headerHorizontalPadding)
        .padding(.top, StickerTrayLayout.headerTopPadding)
    }

    private var layoutRow: some View {
        row(title: "排版") {
            ForEach(CollageLayout.allCases) { item in
                Button { layout = item } label: {
                    VStack(spacing: 6) {
                        CollageGridView(layout: item, spacing: 1.5, cornerRadius: 2) { _ in
                            Rectangle().fill(layout == item ? Color.white : Color.purple.opacity(0.45))
                        }
                        .frame(width: 38, height: 42)
                        Text(item.title).font(.caption2.weight(.medium))
                    }
                    .padding(.vertical, 8)
                    .frame(width: 74)
                    .background(
                        layout == item ? Color.pink : Color.purple.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(layout == item ? .white : .purple)
                }
                .accessibilityLabel("排版：\(item.title)")
            }
        }
    }

    private var styleRow: some View {
        row(title: "花边") {
            ForEach(CollageStyle.allCases) { item in
                Button { style = item } label: {
                    Label(item.title, systemImage: item.iconName)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            style == item ? Color.pink : Color.purple.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(style == item ? .white : .purple)
                }
                .accessibilityLabel("花边：\(item.title)")
            }
        }
    }

    private var modeRow: some View {
        row(title: "拍法") {
            ForEach(CollageCaptureMode.allCases) { item in
                Button { mode = item } label: {
                    Label(item.title, systemImage: item.iconName)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            mode == item ? Color.pink : Color.purple.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(mode == item ? .white : .purple)
                }
                .accessibilityLabel("拍法：\(item.title)")
            }
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            Text("开始拍摄")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(.pink, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, StickerTrayLayout.gridHorizontalPadding)
        .padding(.top, 4)
        .accessibilityLabel("开始拍摄大头贴")
    }

    private func row<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple.opacity(0.7))
                .padding(.horizontal, StickerTrayLayout.headerHorizontalPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content()
                }
                .padding(.horizontal, StickerTrayLayout.categoryStripContentPadding)
            }
        }
    }
}
```

- [ ] **Step 2: 登记进工程并编译**

Run: `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/CollageTrayView.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(大头贴): 添加排版花边拍法面板"
```

---

### Task 8: 接入相机界面

**Files:**
- Modify: `CuteStickerCamera/Core/CameraControlGrouping.swift`
- Modify: `CuteStickerCamera/Views/CameraScreen.swift`
- Modify: `CuteStickerCameraTests/Core/StickerCanvasTests.swift:36-50`

- [ ] **Step 1: 改快捷键测试（会先失败）**

`StickerCanvasTests.swift` 里 `testCameraControlsKeepStickersAndFramesAsTheOnlyQuickActions` 断言快捷键只有两个，现在要加大头贴。把这个方法整体替换成：

```swift
    func testCameraControlsKeepStickersFramesAndCollageAsQuickActions() {
        XCTAssertEqual(CameraControlGrouping.quickActions, [.stickers, .frames, .collage])
        XCTAssertEqual(
            CameraControlGrouping.settingsActions,
            [.aspectRatio, .sound, .timer]
        )
        XCTAssertEqual(
            CameraControlGrouping.expandedSettingsActions,
            [.pictureInPicture, .sound, .timer, .aspectRatio]
        )
        XCTAssertEqual(CameraControlGrouping.bottomTrailingAction, .switchCamera)
    }
```

- [ ] **Step 2: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/StickerCanvasTests/testCameraControlsKeepStickersFramesAndCollageAsQuickActions`
Expected: 编译失败，报 `type 'CameraControlAction' has no member 'collage'`

- [ ] **Step 3: 加动作枚举**

`CuteStickerCamera/Core/CameraControlGrouping.swift`，在 `case frames` 之后加一行：

```swift
    case collage
```

并把快捷键改成：

```swift
    static let quickActions: [CameraControlAction] = [.stickers, .frames, .collage]
```

- [ ] **Step 4: 跑测试确认通过**

Run: 同 Step 2
Expected: PASS

- [ ] **Step 5: 给 CameraScreen 加状态**

在 `CameraScreen` 的属性区（`@State private var isFrameTrayPresented` 附近）加入：

```swift
    @State private var isCollageTrayPresented = false
    @State private var collageLayout: CollageLayout = .fourGrid
    @State private var collageStyle: CollageStyle = .classicWhite
    @State private var collageMode: CollageCaptureMode = .burstThree
    @State private var collageSession: CollageSession?
    @State private var collageShots: [UIImage] = []
    @State private var collageToken: UUID?
```

- [ ] **Step 6: 加入口按钮**

在 `quickActionButton(for:)` 的 `case .frames` 之后插入：

```swift
        case .collage:
            controlButton(systemImage: "square.grid.2x2.fill") { isCollageTrayPresented = true }
                .accessibilityLabel("大头贴")
```

- [ ] **Step 7: 挂面板**

在 `.sheet(isPresented: $isFrameTrayPresented)` 之后追加：

```swift
            .sheet(isPresented: $isCollageTrayPresented) {
                CollageTrayView(
                    layout: $collageLayout,
                    style: $collageStyle,
                    mode: $collageMode,
                    onStart: startCollage,
                    onClose: { isCollageTrayPresented = false }
                )
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled()
            }
```

- [ ] **Step 8: 显示进度缩略图**

把顶部那段

```swift
                    HStack {
                        Spacer()
                        settingsControl
                    }
```

替换为：

```swift
                    HStack(alignment: .top) {
                        if let session = collageSession {
                            CollageProgressView(
                                layout: session.layout,
                                thumbnails: collageShots,
                                currentIndex: session.currentIndex,
                                width: min(96, min(contentRect.width, contentRect.height) * 0.22),
                                onCancel: { cancelCollage() }
                            )
                        }
                        Spacer()
                        settingsControl
                    }
```

- [ ] **Step 9: 拍照回调分流**

把 `.onReceive(camera.$capturedImage.compactMap { $0 })` 的闭包替换为：

```swift
            .onReceive(camera.$capturedImage.compactMap { $0 }) { image in
                if collageSession == nil {
                    saveComposed(image, previewSize: contentRect.size, frameStyle: frameStyle)
                } else {
                    handleCollageShot(image, previewSize: contentRect.size, frameStyle: frameStyle)
                }
            }
```

- [ ] **Step 10: 写大头贴流程**

在 `cancelTimerCapture()` 方法之后插入：

```swift
    private func startCollage() {
        let session = CollageSession(layout: collageLayout, style: collageStyle, mode: collageMode)
        collageSession = session
        collageShots = []
        isCollageTrayPresented = false
        guard let seconds = session.mode.countdownSeconds else { return }
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
                    cancelCollage(message: PhotoComposerError.unableToCreateImage.errorDescription)
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
        collageSession = nil
        collageShots = []
        collageToken = nil
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

    private func cancelCollage(message text: String? = nil) {
        collageToken = nil
        collageSession = nil
        collageShots = []
        timerCountdown = nil
        if let text { message = text }
    }
```

- [ ] **Step 11: 改快门与画幅**

`triggerCapture()` 整体替换为：

```swift
    private func triggerCapture() {
        if let session = collageSession {
            guard !session.mode.isBurst else { return }
            capturePhoto()
            return
        }
        guard isTimerEnabled else {
            capturePhoto()
            return
        }
        startTimerCapture()
    }
```

`expandedSettingsButton(for:)` 里 `case .aspectRatio` 的按钮追加一行禁用：

```swift
            .disabled(collageSession != nil)
```

- [ ] **Step 12: 生命周期清理**

`.onDisappear` 和 `scenePhase == .background` 两处各追加一行 `cancelCollage()`：

```swift
            .onDisappear {
                cancelTimerCapture()
                cancelCollage()
                camera.stop()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active { camera.start() }
                if phase == .background {
                    cancelTimerCapture()
                    cancelCollage()
                    camera.stop()
                }
            }
```

- [ ] **Step 13: 相机异常时中止大头贴**

spec 要求拍摄途中相机中断、权限丢失或单格拍照失败时终止整次拍摄，不保存残缺拼贴。在 `.onChange(of: scenePhase)` 之后追加两个监听：

```swift
            .onChange(of: camera.permissionState) { state in
                guard collageSession != nil, state != .ready else { return }
                cancelCollage()
            }
            .onChange(of: camera.cameraMessage) { cameraMessage in
                guard collageSession != nil, cameraMessage != nil else { return }
                cancelCollage()
            }
```

相机自己的提示语会照常显示，这里只负责丢弃已拍格子并退出大头贴模式。

- [ ] **Step 14: 跑全量测试**

Run: 完整的 `xcodebuild ... test` 命令
Expected: 全部 PASS，`TEST SUCCEEDED`

- [ ] **Step 15: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/CameraControlGrouping.swift CuteStickerCamera/Views/CameraScreen.swift CuteStickerCameraTests/Core/StickerCanvasTests.swift
git commit -m "feat(大头贴): 接入相机界面拍摄流程"
```

---

### Task 9: 验收

**Files:**
- Create: `docs/verification/2026-09-23-photo-booth-collage.md`

- [ ] **Step 1: 模拟器回归**

Run: 完整的 `xcodebuild ... test` 命令
Expected: `TEST SUCCEEDED`，记录用例总数与失败数

- [ ] **Step 2: 模拟器目视检查**

启动模拟器 iPhone 18 Pro，逐项确认并截图存进 `docs/verification/`：

- 右侧快捷键变成贴纸、边框、大头贴三个。
- 大头贴面板三排都能横滑，选中项是粉色高亮。
- 选四宫格开始拍摄后，左上角出现进度缩略图，当前格粉色闪烁。
- 点取消按钮能立即退出大头贴模式，快捷键与画幅按钮恢复可用。
- 大头贴模式下画幅按钮为禁用态。

- [ ] **Step 3: 真机验收**

在真机上完整跑三轮，检查系统照片里的成片：

- 四宫格 + 经典白边 + 连拍 3 秒：四格顺序为左上、右上、左下、右下，留白均匀。
- 竖排四格 + 波浪花边 + 连拍 5 秒：成片为竖长条，四边有扇贝花边。
- 上二下一 + 星星点点 + 逐格手动：每格单独点快门，中途加贴纸只影响后续格子。

另外确认：拍摄途中切后台再回来不残留大头贴状态；拍完提示语为“大头贴拍好啦！已经保存到系统照片 ✨”。

- [ ] **Step 4: 写验证记录**

创建 `docs/verification/2026-09-23-photo-booth-collage.md`，按 `docs/verification/2026-09-17-dual-camera-restoration.md` 的结构记录：已执行项、测试命令与结果、尚未完成的真机验收项、环境说明。

- [ ] **Step 5: 提交（先征得用户许可）**

```bash
git add docs/verification/2026-09-23-photo-booth-collage.md
git commit -m "chore(大头贴): 添加验收记录"
```
