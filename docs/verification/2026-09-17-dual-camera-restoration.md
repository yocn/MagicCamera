# 双摄恢复验证记录

## 已执行

- 已知第一次崩溃原因：自动镜像开启时写入手动镜像属性。恢复版统一检查支持能力，先关闭自动镜像再写入手动镜像。
- 新增布局、预算、入口能力及双路合成测试。恢复前构建测试因缺少对应类型/接口失败。
- 贴纸与小窗重叠回归：`testPictureInPictureLetsEmptyTouchesPassButKeepsOverlappingStickersEditable` 在旧命中实现下实际失败；调整为空白穿透、贴纸优先后通过。
- 完整 iOS 模拟器测试：22 项，0 失败，`TEST SUCCEEDED`（2026-09-17 19:38）。
- 真机签名构建：`BUILD SUCCEEDED`。
- `git diff --check` 通过。
- 独立静态审查发现的重叠命中、相机提示清除、设备原格式快照顺序问题均已处理并复查。

测试命令：

```sh
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'platform=iOS Simulator,id=D9A7DE70-A534-4CF7-B2C3-2DD6C37A4382' -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
xcodebuild -project CuteStickerCamera.xcodeproj -scheme CuteStickerCamera -destination 'generic/platform=iOS' -derivedDataPath /tmp/sticker-dual-device-build build
```

## 尚未完成的真机验收

不使用 Device Hub 的 View Screen；在手机本地操作：

- 设置 → 画中画双摄：后摄主画面、前摄镜像小窗同时有实时画面。
- 拖动小窗，切换全屏/3:4，确认仍在画幅内。
- 拍照并在系统照片检查前摄小窗的位置、方向、镜像、贴纸与边框层级；连续拍摄 10 张。
- 关闭双摄恢复原单摄，前后镜头切换正常。
- 进入后台后相机释放；返回默认单摄。退出应用后系统相机正常。
- 真机中断/压力降级尚未人为触发验证，不能用静态审查或模拟器通过代替。

## 环境说明

- 本轮单项测试曾卡在模拟器启动阶段，终止本轮测试进程、重新启动该模拟器并关闭并行测试后完成验证；未重启手机。
- 仓库原有 Swift Package 测试因 CameraPermissionState 不在 Core target 而无法编译，本次采用完整 iOS XCTest target 验证。
- Xcode 27 对 iOS 16 XCTest 链接版本和既有测试中未修改变量发出警告；不影响本轮 iOS 测试通过。
- 当前工作分支：`codex/restore-dual-camera`，代码未提交。
