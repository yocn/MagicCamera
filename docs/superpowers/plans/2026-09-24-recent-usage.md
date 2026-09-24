# 最近使用 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 贴纸和边框面板各记住最近用过的 16 个，放在分类条最左的「最近」页。

**Architecture:** 排序与容量逻辑做成 `Core/` 里的纯值类型，可单测；持久化包一层 `UserDefaults`；两个面板各自在分类条前面插入一个虚拟分类，页面内容按 id 分支。

**Tech Stack:** Swift、SwiftUI、XCTest。

**Spec:** `docs/superpowers/specs/2026-09-24-recent-usage-design.md`

## Global Constraints

- `Core/` 下的新文件只能 import `Foundation`，不得 import UIKit / SwiftUI。
- commit message 格式 `<type>(<scope>): <中文描述>`，只有标题行，不加 `Co-Authored-By`。
- **每次 commit 前必须向用户显式请求许可**。
- 新增源文件用 `/tmp/pbx_add.py` 登记，执行前先查当前最大 ID 往后顺延（codex 在并行加文件，避免撞号）。
- 工作区目前有 28 个未跟踪的孤儿 PNG，属于待定事项，任何 `git add` 都不要把它们带上。

## 测试命令

```sh
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera \
  -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

---

### Task 1: 最近使用模型

**Files:**
- Create: `CuteStickerCamera/Core/RecentUsage.swift`
- Create: `CuteStickerCameraTests/Core/RecentUsageTests.swift`
- Modify: `CuteStickerCamera.xcodeproj/project.pbxproj`

- [ ] **Step 1: 查 ID 并登记**

```sh
grep -oE "B0[0-9][0-9]" CuteStickerCamera.xcodeproj/project.pbxproj | sort -u | tail -1
grep -oE "F0[0-9][0-9]" CuteStickerCamera.xcodeproj/project.pbxproj | sort -u | tail -1
grep -oE "B2[0-9][0-9]" CuteStickerCamera.xcodeproj/project.pbxproj | sort -u | tail -1
```

用顺延的 ID：

```sh
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj RecentUsage.swift B043 F045 DoodleTool.swift B040 F042
python3 /tmp/pbx_add.py CuteStickerCamera.xcodeproj/project.pbxproj RecentUsageTests.swift B219 F219 DoodleTests.swift B218 F218
```

- [ ] **Step 2: 写失败的测试**

创建 `CuteStickerCameraTests/Core/RecentUsageTests.swift`：

```swift
import XCTest
#if canImport(CuteStickerCamera)
@testable import CuteStickerCamera
#else
@testable import CuteStickerCore
#endif

final class RecentUsageTests: XCTestCase {
    func testNewItemGoesToTheFront() {
        var list = RecentUsageList()

        list.use("a")
        list.use("b")

        XCTAssertEqual(list.items, ["b", "a"])
    }

    func testReusingAnItemMovesItToTheFrontWithoutDuplicating() {
        var list = RecentUsageList()
        list.use("a")
        list.use("b")
        list.use("c")

        list.use("a")

        XCTAssertEqual(list.items, ["a", "c", "b"], "重复使用应该提到最前而不是新增一条")
    }

    func testListStopsAtSixteenAndDropsTheOldest() {
        var list = RecentUsageList()
        for index in 0..<16 {
            list.use("item\(index)")
        }
        XCTAssertEqual(list.items.count, 16)
        XCTAssertEqual(list.items.last, "item0", "满 16 条时最旧的应该还在队尾")

        list.use("newcomer")

        XCTAssertEqual(list.items.count, 16)
        XCTAssertEqual(list.items.first, "newcomer")
        XCTAssertFalse(list.items.contains("item0"), "超出容量后最旧的那条应被挤掉")
    }

    func testStorePersistsOrderAcrossInstances() {
        let suiteName = "RecentUsageStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        var store = RecentUsageStore(key: "recentTest", defaults: defaults)
        store.use("a")
        store.use("b")

        let reloaded = RecentUsageStore(key: "recentTest", defaults: defaults)
        XCTAssertEqual(reloaded.items, ["b", "a"])
    }
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/RecentUsageTests`
Expected: 编译失败，报 `cannot find 'RecentUsageList' in scope`

- [ ] **Step 4: 写实现**

创建 `CuteStickerCamera/Core/RecentUsage.swift`：

```swift
import Foundation

public struct RecentUsageList: Equatable, Sendable {
    public static let capacity = 16

    public private(set) var items: [String]

    public init(items: [String] = []) {
        self.items = Array(items.prefix(Self.capacity))
    }

    /// 刚用过的排最前；已经在列表里的提到最前，不产生重复。
    public mutating func use(_ id: String) {
        items.removeAll { $0 == id }
        items.insert(id, at: 0)
        if items.count > Self.capacity {
            items.removeLast(items.count - Self.capacity)
        }
    }
}

public struct RecentUsageStore {
    private let key: String
    private let defaults: UserDefaults
    private var list: RecentUsageList

    public init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
        self.list = RecentUsageList(items: defaults.stringArray(forKey: key) ?? [])
    }

    public var items: [String] { list.items }

    public mutating func use(_ id: String) {
        list.use(id)
        defaults.set(list.items, forKey: key)
    }
}

public enum RecentUsageKey {
    public static let stickers = "recentStickers"
    public static let frames = "recentFrames"
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `xcodebuild ... test -only-testing:CuteStickerCameraTests/RecentUsageTests`
Expected: 4 个用例全部 PASS

- [ ] **Step 6: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Core/RecentUsage.swift CuteStickerCameraTests/Core/RecentUsageTests.swift CuteStickerCamera.xcodeproj/project.pbxproj
git commit -m "feat(最近使用): 添加最近使用列表模型"
```

---

### Task 2: 贴纸面板接入

**Files:**
- Modify: `CuteStickerCamera/Views/StickerTrayView.swift`
- Modify: `CuteStickerCamera/Views/CameraScreen.swift`

- [ ] **Step 1: 给贴纸面板加最近页**

`StickerTrayView` 顶部属性区加入：

```swift
    let recentAssetNames: [String]
```

把 `selectedCategoryID` 的初值改成由外部决定，加一个自定义 init：

```swift
    init(
        recentAssetNames: [String],
        onPick: @escaping (String) -> Void,
        onMagicPick: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.recentAssetNames = recentAssetNames
        self.onPick = onPick
        self.onMagicPick = onMagicPick
        self.onClose = onClose
        // 有历史就停在最近，没有就回到第一个分类。
        _selectedCategoryID = State(initialValue: recentAssetNames.isEmpty ? "hair" : Self.recentTabID)
    }

    static let recentTabID = "recent"
```

分类条的 `ForEach` 前面插入最近胶囊。把 `categoryStrip` 里的 `HStack(spacing: 8) {` 之后、`ForEach(StickerCategoryPager.categories)` 之前加入：

```swift
                        Button {
                            selectCategory(Self.recentTabID)
                        } label: {
                            Label("最近", systemImage: "clock.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedCategoryID == Self.recentTabID ? .white : .purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategoryID == Self.recentTabID ? .pink : .purple.opacity(0.1),
                                    in: Capsule()
                                )
                        }
                        .id(Self.recentTabID)
```

`TabView` 的 `ForEach` 前面插入最近页：

```swift
                recentPage
                    .tag(Self.recentTabID)
```

在 `stickerPage(for:)` 之前加入最近页实现：

```swift
    private var recentPage: some View {
        // 素材可能被删或改名，查不到图的直接不显示。
        let names = recentAssetNames.filter { StickerImageProvider.image(named: $0) != nil }

        return Group {
            if names.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.purple.opacity(0.4))
                    Text("用过的贴纸会出现在这里 ✨")
                        .font(.subheadline)
                        .foregroundStyle(.purple.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 10) {
                        ForEach(names, id: \.self) { name in
                            Button { onPick(name) } label: {
                                Image(uiImage: StickerImageProvider.image(named: name) ?? UIImage())
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 58, height: 58)
                                    .padding(5)
                                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .pink.opacity(0.18), radius: 5, y: 2)
                            }
                            .accessibilityLabel("最近用过的贴纸：\(name)")
                        }
                    }
                }
                .padding(.horizontal, StickerTrayLayout.gridHorizontalPadding)
            }
        }
    }
```

- [ ] **Step 2: CameraScreen 记录并传入**

属性区加入：

```swift
    @State private var recentStickers = RecentUsageStore(key: RecentUsageKey.stickers)
```

把贴纸 sheet 的调用改成：

```swift
                StickerTrayView(recentAssetNames: recentStickers.items) { name in
                    canvas.add(assetName: name)
                    recentStickers.use(name)
                    isStickerTrayPresented = false
                } onMagicPick: {
                    let outfit = MagicStickerOutfits.random()
                    canvas.add(layers: outfit.placements.map(\.layer))
                    outfit.placements.forEach { recentStickers.use($0.assetName) }
                    showMessage("\(outfit.title)搭配完成 ✨")
                    isStickerTrayPresented = false
                } onClose: {
                    isStickerTrayPresented = false
                }
```

- [ ] **Step 3: 编译**

Run: `xcodebuild ... build CODE_SIGNING_ALLOWED=NO`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/StickerTrayView.swift CuteStickerCamera/Views/CameraScreen.swift
git commit -m "feat(最近使用): 贴纸面板增加最近页"
```

---

### Task 3: 边框面板接入

**Files:**
- Modify: `CuteStickerCamera/Views/FrameTrayView.swift`
- Modify: `CuteStickerCamera/Views/CameraScreen.swift`

- [ ] **Step 1: 给边框面板加最近页**

`FrameTrayView` 属性区加入 `let recentStyles: [FrameStyle]`，并把 init 改成：

```swift
    init(
        selected: FrameStyle,
        recentStyles: [FrameStyle],
        onPick: @escaping (FrameStyle) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selected = selected
        self.recentStyles = recentStyles
        self.onPick = onPick
        self.onClose = onClose
        _selectedTab = State(initialValue: recentStyles.isEmpty ? .category(selected.category) : .recent)
    }
```

分页标识改成枚举，放在文件末尾：

```swift
enum FrameTrayTab: Hashable {
    case recent
    case category(FrameCategory)
}
```

把 `@State private var selectedCategory: FrameCategory` 换成 `@State private var selectedTab: FrameTrayTab`，分类条和 `TabView` 的 `ForEach` 都改用 `FrameTrayTab`，最左插入 `.recent`。最近页复用 `FrameChoiceButton`，网格同样 4 列：

```swift
    private var recentPage: some View {
        let styles = recentStyles.filter { $0.assetName != nil }

        return Group {
            if styles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.largeTitle)
                        .foregroundStyle(.purple.opacity(0.4))
                    Text("用过的边框会出现在这里 ✨")
                        .font(.subheadline)
                        .foregroundStyle(.purple.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                        ForEach(styles, id: \.self) { style in
                            FrameChoiceButton(style: style, isSelected: style == selected) {
                                onPick(style)
                            }
                        }
                    }
                    .padding(.horizontal, TrayLayout.horizontalPadding)
                }
            }
        }
    }
```

- [ ] **Step 2: CameraScreen 记录并传入**

属性区加入：

```swift
    @State private var recentFrames = RecentUsageStore(key: RecentUsageKey.frames)
```

边框 sheet 的调用改成：

```swift
                FrameTrayView(
                    selected: frameStyle,
                    recentStyles: recentFrames.items.compactMap(FrameStyle.init(rawValue:)),
                    onPick: { style in
                        frameStyle = style
                        if style != .none { recentFrames.use(style.rawValue) }
                        isFrameTrayPresented = false
                    },
                    onClose: { isFrameTrayPresented = false }
                )
```

- [ ] **Step 3: 编译并跑全量测试**

Run: 完整的 `xcodebuild ... test` 命令
Expected: 全部 PASS

- [ ] **Step 4: 提交（先征得用户许可）**

```bash
git add CuteStickerCamera/Views/FrameTrayView.swift CuteStickerCamera/Views/CameraScreen.swift
git commit -m "feat(最近使用): 边框面板增加最近页"
```

---

### Task 4: 验收

- [ ] **Step 1: 模拟器目视**

- 两个面板的分类条最左都有「最近」胶囊。
- 首次打开（无历史）时不在最近页，而是停在贴纸的发型 / 边框的当前分类，且切到最近页显示占位文字。
- 选几个贴纸和边框后重开面板，默认停在最近页，顺序是最新的在最前。
- 重复选同一个，确认它跳到第一位而不是出现两条。

- [ ] **Step 2: 真机验收**

杀掉应用重开，确认两个最近列表都还在、顺序没变。

- [ ] **Step 3: 写验证记录并提交（先征得用户许可）**

创建 `docs/verification/2026-09-24-recent-usage.md`，记录测试结果与真机验收情况。
