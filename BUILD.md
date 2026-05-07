# 构建说明

本文档记录在现代 macOS（Apple Silicon）环境下从源码构建 Spectacle 并打包为 DMG 的完整步骤。

## 环境要求

- macOS 11.0+（Apple Silicon 或 Intel）
- Xcode（完整安装，非 Command Line Tools）
- Homebrew

## 一次性准备

### 1. 安装 Xcode

从 App Store 安装 Xcode，安装完成后切换 active developer directory：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 2. 安装 Carthage

```bash
brew install carthage
```

### 3. 准备依赖

Carthage 无法自动构建所有依赖（部分依赖在新版 Xcode 下签名或 deployment target 存在兼容性问题），需要手动下载预编译包。

**下载 Sparkle 1.27.3：**

```bash
curl -L -o /tmp/Sparkle-1.27.3.tar.xz \
  "https://github.com/sparkle-project/Sparkle/releases/download/1.27.3/Sparkle-1.27.3.tar.xz"

mkdir -p /tmp/Sparkle-extract
tar -xf /tmp/Sparkle-1.27.3.tar.xz -C /tmp/Sparkle-extract
mkdir -p Carthage/Build/Mac
cp -R /tmp/Sparkle-extract/Sparkle.framework Carthage/Build/Mac/
cp -R /tmp/Sparkle-extract/Sparkle.framework.dSYM Carthage/Build/Mac/
```

**下载 OCMockito 5.1.3：**

```bash
curl -L -o /tmp/OCMockito-5.1.3.zip \
  "https://github.com/jonreid/OCMockito/releases/download/v5.1.3/OCMockito-5.1.3.zip"

mkdir -p /tmp/OCMockito-extract
unzip -o /tmp/OCMockito-5.1.3.zip -d /tmp/OCMockito-extract/
cp -R /tmp/OCMockito-extract/OCMockito-5.1.3/OCMockito.framework Carthage/Build/Mac/
```

**通过 Carthage 拉取其余依赖（OCHamcrest、Expecta）：**

```bash
carthage update --platform Mac
```

> 此命令会报 OCMockito 构建失败的错误，可以忽略——OCMockito 已在上一步手动放置。
> 完成后确认 `Carthage/Build/Mac/` 中包含以下文件：
> - `Expecta.framework`
> - `OCHamcrest.framework`
> - `OCMockito.framework`
> - `Sparkle.framework`

## 构建

```bash
xcodebuild -project Spectacle.xcodeproj -target Spectacle -configuration Release build
```

构建产物位于 `build/Release/Spectacle.app`。

构建结果是包含 `x86_64` 和 `arm64` 的 Universal Binary，可在 Intel 和 Apple Silicon Mac 上原生运行：

```bash
lipo -info build/Release/Spectacle.app/Contents/MacOS/Spectacle
# Architectures in the fat file: ... are: x86_64 arm64
```

## 打包 DMG

```bash
hdiutil create \
  -volname Spectacle \
  -srcfolder build/Release/Spectacle.app \
  -ov \
  -format UDZO \
  Spectacle.dmg
```

生成的 `Spectacle.dmg` 即可分发。

## 首次运行

Spectacle 需要**辅助功能（Accessibility）权限**才能移动窗口，首次启动时会弹出授权请求。

如果之前授权过旧路径的 Spectacle，新构建的 app 需要重新授权：

```bash
sudo tccutil reset Accessibility com.divisiblebyzero.Spectacle
```

然后重新启动 app，按提示前往**系统设置 → 隐私与安全性 → 辅助功能**授权。未授权时快捷键注册可以成功，但按下快捷键后窗口不会移动。

## 说明

**为什么不用 `carthage update` 一键完成？**

- Sparkle 1.x 包含命令行工具（`fileop`），Carthage 构建时传入空签名导致失败；官方 release 的预编译包是正常签名的 Universal Binary，直接使用即可。
- OCMockito 5.x 的 iOS scheme 依赖 OCHamcrest iOS 切片，在 `--platform Mac` 下触发构建错误；预编译包只含 x86_64，仅影响测试 target，主 app 不受影响。
- OCHamcrest 7.x 在 Xcode 26+ 下因 `libarclite` 被移除而无法从源码编译，Carthage 下载的预编译 binary 可正常使用。

**为什么用 `-target Spectacle` 而不是 `-scheme Spectacle`？**

`-scheme Spectacle` 会同时构建测试 target `SpectacleSpecs`，而测试依赖（Specta）没有预编译包，在新版 Xcode 下也无法从源码构建。`-target Spectacle` 只构建主 app，不触发测试 target。
