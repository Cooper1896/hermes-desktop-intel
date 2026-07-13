# 本地构建说明

在 Intel Mac 上从本仓库编出 Hermes Desktop x64。

## 结构

| 部分 | 路径 | 说明 |
|------|------|------|
| 桌面壳 | `upstream/apps/desktop` | Electron + React |
| 共享包 | `upstream/apps/shared` | `@hermes/shared` |
| agent | 首次运行或 CLI 装到 `~/.hermes` | Python + `hermes serve` |
| Setup 安装器 | `upstream/apps/bootstrap-installer` | Tauri，可选，经常有坑 |

日常只要 Desktop 编出来就够用。

## 环境

```bash
./scripts/setup-deps.sh
```

- Node：`^20.19` 或 `>=22.12`（22 最省事）
- Python ≥ 3.11
- Xcode CLT：`xcode-select -p`
- `git` / `file` / `lipo` / `codesign` / `shasum`

装 Node：

```bash
brew install node@22
# 或 nvm install 22
# 或解压官方 darwin-x64 包到 ~/.local（见 README）
```

Electron 下载慢：

```bash
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

签名：

- 本地默认 `CSC_IDENTITY_AUTO_DISCOVERY=false`，编完跑 `./scripts/sign-adhoc.sh`
- 有开发者证书再配 `CSC_LINK` 等，见 electron-builder 文档

## 一键构建

```bash
./scripts/setup-deps.sh
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh
```

脚本会在 `upstream/` 里：

1. `npm install --workspace apps/desktop`
2. `npm run build --workspace apps/desktop`
3. `npm run builder -- --mac --x64 --publish=never`  
   （dmg/zip 写在 package.json 的 mac.target 里，不要把 dmg zip 写在 `--x64` 后面）

产物拷到仓库根目录 `dist/`。

手动等价命令：

```bash
cd upstream
npm install --workspace apps/desktop
npm run build --workspace apps/desktop
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac --x64 --publish=never
file apps/desktop/release/mac/Hermes.app/Contents/MacOS/Hermes
```

## 可选：Bootstrap

```bash
./scripts/build-bootstrap-mac-x64.sh
```

要 Rust，`x86_64-apple-darwin` target。DMG 挂了就只会给你 `.app` 的 zip。

## 验收

```bash
./scripts/verify-mac-x64.sh
```

主二进制必须是 x86_64；`node-pty` 里最好有 `darwin-x64`。  
`dist/SHA256SUMS` 会列 dmg/zip。

冒烟：

```bash
open dist/Hermes.app
# 被拦就：xattr -cr dist/Hermes.app
```

## 升级上游

```bash
./scripts/pin-upstream.sh <tag 或 sha>
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
git add upstream upstream-ref.txt
git commit -m "chore: bump upstream"
```

Intel 官方不支持，每次 bump 都建议本机点开跑一下。

## CI

`.github/workflows/`：

- `build-mac-x64.yml` — push / PR 编一次，artifact 上传
- `release.yml` — 推 `v*` tag 发 Release

Runner 可能是 arm64，靠 electron-builder 交叉出 x64。发版前最好在真 Intel 上再验一遍。

仓库变量可设 `ELECTRON_MIRROR`。

## 常见问题

**卡在下 Electron**  
清缓存 + 换 mirror：

```bash
rm -f "$HOME/Library/Caches/electron"/electron-*.zip
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

**编出来是 arm64**  
确认带了 `--x64` 和 `npm_config_arch=x64`，别在 arm 机器上裸跑默认 pack。

**打不开 / 已损坏**  

```bash
codesign --force --deep --sign - /path/to/Hermes.app
xattr -cr /path/to/Hermes.app
```

**npm workspace 报错**  
一定在 monorepo 根（`upstream/`）装依赖，不要只进 `apps/desktop` 瞎装。
