# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目简介

Spectacle 是一个 macOS 窗口管理工具（已停止主动维护），使用 Objective-C 编写，通过 OS X Accessibility Protocol 控制窗口位置和大小。推荐的开源替代品是 [Rectangle](https://github.com/rxhanson/Rectangle)（其代码基于 Spectacle）。

## 构建与运行

**首次构建前**，需要用 Carthage 拉取依赖：

```bash
carthage bootstrap --platform Mac
```

然后在 Xcode 中打开项目：

```bash
open Spectacle.xcodeproj
```

按 `⌘R` 运行，按 `⌘U` 执行测试。

**命令行构建与测试：**

```bash
xcodebuild -project Spectacle.xcodeproj -scheme Spectacle test | xcpretty
```

## 依赖项（Carthage）

- **Specta + Expecta**：BDD 风格测试框架
- **OCHamcrest + OCMockito**：匹配器与 Mock 库
- **Sparkle**：自动更新框架

## 代码架构

### 核心数据流

```
快捷键触发 → SpectacleShortcutManager
          → SpectacleWindowPositionManager.moveFrontmostWindowElement:action:
          → SpectacleWindowPositionCalculator（计算目标 CGRect）
          → id<SpectacleWindowMover>（将计算结果应用到窗口）
```

### 关键模块

**窗口位置计算层**
- `SpectacleWindowPositionCalculator`：核心计算器，根据 action 和屏幕尺寸计算目标窗口矩形
- `SpectacleWindowPositionManager`：协调器，获取当前屏幕信息，调用计算器，再调用 Mover；同时管理 undo/redo 历史
- `SpectacleWindowAction`：用 `typedef NSString` 定义的所有窗口动作常量（左半、右半、全屏等 19 种）

**窗口移动层（装饰器链）**
- `SpectacleWindowMover`（protocol）：定义 `moveWindowRect:frameOfScreen:visibleFrameOfScreen:frontmostWindowElement:action:`
- `SpectacleStandardWindowMover`：标准移动实现
- `SpectacleQuantizedWindowMover`：处理 Terminal 等有尺寸约束的窗口（量化对齐）
- `SpectacleBestEffortWindowMover`：迭代尝试，直到窗口尽可能接近目标尺寸

**快捷键层**
- `SpectacleShortcut`：表示单个快捷键（modifier keys + character key）
- `SpectacleShortcutManager`：注册全局热键，触发对应 action
- `SpectacleShortcutStorage`（protocol）：存储接口，有三个实现：`UserDefaults`、`JSON`、`Migrating`（迁移旧格式）
- `SpectacleShortcutTranslations`：在 key code / modifier flags 与人类可读字符串之间互相转换

**屏幕检测**
- `SpectacleScreenDetector`：检测当前窗口所在屏幕及目标屏幕，返回 `SpectacleScreenDetectionResult`

**测试**（`SpectacleSpecs/`）
- 每个窗口 action 对应一个 `*Spec.m` 文件，使用 Specta + Expecta 框架编写，测试 `SpectacleWindowPositionCalculator` 的输出
