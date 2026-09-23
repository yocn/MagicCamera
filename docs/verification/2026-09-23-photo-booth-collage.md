# 大头贴拼贴验证记录

## 已执行

- 逐任务 TDD：排版、花边、状态机、合成四层都先写失败测试再实现，每层跑过“失败 → 通过”两轮。
- 新增 12 个 `CollageTests` 用例：排版铺满不重叠、竖排四格画布与格子比例、正方形排版、花边参数区间、无边样式不画装饰、装饰样式留边距、状态机推进与越界保护、连拍倒计时参数、四格各自取到正确颜色、格数不符抛错、白边样式留白。
- 提取 `ImageCropping.swift` 后跑过 `StickerRenderTransformTests`，像素级的画中画合成用例仍通过，证明裁剪行为未变。
- 完整 iOS 模拟器测试：50 项，0 失败，`TEST SUCCEEDED`（2026-09-23 15:06）。
- 模拟器目视：右侧快捷键为贴纸、边框、大头贴三个；大头贴面板三排选择器与开始按钮渲染正确，选中项粉色高亮（`collage-tray-panel.png`）。
- 合成样张目视：导出九种排版与花边组合的纯色样张逐一检查（`collage-four-grid-wave.png`、`collage-four-grid-stars.png`、`collage-vertical-four-wave.png`）。
- 修掉一处目视才暴露的问题：星星装饰原本画在画布四角，被画布边缘裁掉大半；改为骑在照片四角上，半径取外边距的 0.8。

测试命令：

```sh
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera \
  -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' \
  -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

## 真机验收

- 拍摄链路由用户在 iPhone 16 Pro Max 上实际走通并确认可用（2026-09-23）。
- 模拟器没有摄像头，这条链路无法在模拟器复现，后续回归仍需真机。

尚未逐项确认、改动相关代码时要重新过一遍的：

- 与画中画双摄同时开启时，小窗按每格独立合成。
- 拍摄途中切后台再回来不残留状态。

## 用户反馈后的调整（2026-09-23）

- 开启模式与开始拍摄拆开：点大头贴图标只开面板，面板里任选一项即进入模式并亮出浮层，按快门才开拍。
- 浮层改为可拖动，显示真实排版与花边，带拍法角标；关闭按钮独立成层定位在角外，避免被拖动手势吞掉点击。
- 浮层预览改为 body 内同步取用加缓存，消除切排版时慢一拍的问题。
- 拍满一轮后保留模式与配置，直接开下一轮，退出只由浮层关闭按钮触发。

## 环境说明

- 面板与进度视图无法用 `simctl` 点击触发，面板截图是临时把 `isCollageTrayPresented` 初值改为 `true` 渲染后截取的，截完已还原。
- 花边是代码绘制而非 PNG 素材，所以增加了一轮“导出纯色样张目视”的验证环节；该导出用例是临时加的，验证后已删除。
- 模拟器日志中的 `camera session interrupted/failed` 是模拟器无摄像头导致的既有现象，与本次改动无关。
