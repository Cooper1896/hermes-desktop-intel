# hermes-desktop-intel

非官方的 [Hermes Desktop](https://github.com/NousResearch/hermes-agent) **macOS Intel (x86_64)** 构建。

---

## 直接用（推荐）

到 [Releases](../../releases) 下对应版本的：

- `Hermes-*-mac-x64.dmg` — 拖进「应用程序」
- 或 `.zip` 解压出 `Hermes.app`

Apple Silicon 请用官方包。

---

## 自己编译

### 依赖

- Intel Mac + Xcode CLT
- Node `^20.19` 或 `>=22.12`（建议 22）
- Python ≥ 3.11（跑 agent 用）
- git

### 步骤

```bash
git clone --recurse-submodules https://github.com/Cooper1896/hermes-desktop-intel.git
cd hermes-desktop-intel

./scripts/setup-deps.sh
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh
```

产物在 `dist/`。细节见 [docs/BUILD.md](docs/BUILD.md)。

Electron 下不动可以试：

```bash
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

### 换上游版本

```bash
./scripts/pin-upstream.sh <tag 或 commit>
# 编通之后再 commit 一次 submodule 指针
```

---

## 仓库里有什么

```
scripts/          依赖检查、构建、校验、ad-hoc 签名
upstream/         submodule → NousResearch/hermes-agent（钉死某个 commit）
docs/BUILD.md     构建说明
.github/workflows CI（push / tag 时编 x64）
dist/             本地产物，不进 git
```

| 脚本 | 干啥 |
|------|------|
| `setup-deps.sh` | 检查 Node / Python / CLT |
| `pin-upstream.sh` | 初始化或钉上游 |
| `build-desktop-mac-x64.sh` | 编 Electron 桌面端 |
| `verify-mac-x64.sh` | 确认是 x86_64，写 SHA256SUMS |
| `sign-adhoc.sh` | 没证书时用 `codesign -s -` |
| `build-bootstrap-mac-x64.sh` | 可选，Tauri Setup，经常翻车 |

---

## 注意

- Release 里的包多半是 **ad-hoc 签名、没公证**，别当官方安装包。
- 下载完对一下 `SHA256SUMS` 再好。
- Hermes 能跑命令、动文件，信任模型和官方一样，别乱下不明来源的包。
- 官方随时可能改 desktop 构建方式；Intel 本来就不 support，升级上游后自己再测一遍。

---

## License

MIT，见 [LICENSE](./LICENSE)。  
上游 [hermes-agent](https://github.com/NousResearch/hermes-agent) 也是 MIT，版权归原作者。

## 链接

- [Desktop 文档](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
- [平台支持说明](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support)
- [上游仓库](https://github.com/NousResearch/hermes-agent)
