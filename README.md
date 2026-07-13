# hermes-desktop-intel

此项目为 [Hermes Desktop](https://github.com/NousResearch/hermes-agent) 针对 **macOS Intel (x86_64)** 架构的非官方构建方案。
This project is an unofficial build solution of [Hermes Desktop](https://github.com/NousResearch/hermes-agent) for the **macOS Intel (x86_64)** architecture.

---

## 安装与使用

## Installation & Usage

请前往 [Releases](https://www.google.com/search?q=../../releases) 下载对应版本：
Please go to [Releases](https://www.google.com/search?q=../../releases) to download the corresponding version:

* **DMG 镜像**：下载 `Hermes-*-mac-x64.dmg`，双击并将应用拖拽至 `Applications`（应用程序）目录。
**DMG Image**: Download `Hermes-*-mac-x64.dmg`, double-click, and drag the application to the `Applications` directory.
* **ZIP 压缩包**：下载 `.zip` 文件，解压后直接运行 `Hermes.app`。
**ZIP Archive**: Download the `.zip` file, extract it, and run `Hermes.app` directly.

> **注意**：Apple Silicon (M1/M2/M3 等) 用户请直接使用官方提供的发行版本。
> **Note**: Apple Silicon (M1/M2/M3, etc.) users please use the officially provided release versions directly.

---

## 手动编译

## Manual Compilation

### 环境依赖

### Environment Dependencies

* macOS (Intel 架构) + Xcode Command Line Tools
macOS (Intel architecture) + Xcode Command Line Tools
* Node.js (`^20.19` 或 `>=22.12`，推荐 v22)
Node.js (`^20.19` or `>=22.12`, v22 recommended)
* Python (>= 3.11，用于运行 Agent 核心)
Python (>= 3.11, used for running the Agent core)
* Git
Git

### 编译步骤

### Compilation Steps

```bash
# 克隆仓库及子模块 / Clone the repository and submodules
git clone --recurse-submodules https://github.com/Cooper1896/hermes-desktop-intel.git
cd hermes-desktop-intel

# 执行构建脚本 / Execute build scripts
./scripts/setup-deps.sh
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh

```

构建产物将输出至 `dist/` 目录。详细信息请参阅 [docs/BUILD.md](https://www.google.com/search?q=docs/BUILD.md)。
Build artifacts will be output to the `dist/` directory. For detailed information, please refer to [docs/BUILD.md](https://www.google.com/search?q=docs/BUILD.md).

### 更新上游版本

### Updating Upstream Versions

```bash
./scripts/pin-upstream.sh <tag 或 commit_hash> # <tag or commit_hash>
# 编译通过后，请重新提交 (commit) Submodule 指针变更
# Once compilation passes, please re-commit the Submodule pointer changes

```

---

## 项目结构与脚本说明

## Project Structure & Script Descriptions

### 目录结构

### Directory Structure

```
scripts/           # 依赖检查、构建、校验及签名脚本
                   # Dependency checking, building, verification, and signing scripts
upstream/          # Git Submodule，指向指定的 NousResearch/hermes-agent 提交版本
                   # Git Submodule, pointing to a specific NousResearch/hermes-agent commit
docs/BUILD.md      # 详细的构建指南
                   # Detailed build guide
.github/workflows  # GitHub Actions 自动化流水线
                   # GitHub Actions automation workflow
dist/              # 本地构建产物输出目录（已忽略，不进入 Git 追踪）
                   # Local build artifact output directory (ignored, not tracked by Git)

```

### 脚本清单

### Script Manifest

| 脚本名称 / Script Name | 功能描述 / Functional Description |
| --- | --- |
| `setup-deps.sh` | 检查并验证本地 Node.js、Python 及 Xcode CLT 环境。<br>

<br>Checks and verifies local Node.js, Python, and Xcode CLT environments. |
| `pin-upstream.sh` | 初始化或锁定上游仓库的具体版本。<br>

<br>Initializes or locks specific versions of the upstream repository. |
| `build-desktop-mac-x64.sh` | 构建基于 Electron 的 macOS x64 桌面客户端。<br>

<br>Builds the Electron-based macOS x64 desktop client. |
| `verify-mac-x64.sh` | 验证构建产物的 x86_64 架构合法性并生成 `SHA256SUMS`。<br>

<br>Verifies the x86_64 architecture validity of build artifacts and generates `SHA256SUMS`. |
| `sign-adhoc.sh` | 在无标准证书的环境下为应用执行 Ad-hoc 签名 (`codesign -s -`)。<br>

<br>Performs Ad-hoc signing (`codesign -s -`) for the application in environments without a standard certificate. |
| `build-bootstrap-mac-x64.sh` | （可选）基于 Tauri 的构建脚本，当前处于实验阶段，稳定性较低。<br>

<br>(Optional) Tauri-based build script, currently in an experimental stage with lower stability. |

---

## 注意事项

## Precautions

* **签名**：Releases 中提供的安装包均采用 **Ad-hoc 签名且未经 Apple 官方公证（Notarization）**。请勿将其视作官方签名的正式分发包。
**Signing**: The installation packages provided in Releases all use **Ad-hoc signing and have not been officially notarized (Notarization) by Apple**. Do not treat them as officially signed formal distribution packages.
* **校验**：为确保安装包完整性，建议在下载后手动比对 `SHA256SUMS` 哈希值。
**Verification**: To ensure the integrity of the installation packages, it is recommended to manually compare the `SHA256SUMS` hash values after downloading.

---

## 开源协议

## License

本项目采用 MIT 协议开源，详见 [LICENSE](https://www.google.com/search?q=./LICENSE)。
This project is open-sourced under the MIT License; see [LICENSE](https://www.google.com/search?q=./LICENSE) for details.

上游项目 [hermes-agent](https://github.com/NousResearch/hermes-agent) 亦采用 MIT 协议，版权归原作者所有。
The upstream project [hermes-agent](https://github.com/NousResearch/hermes-agent) also uses the MIT License, with copyrights belonging to the original authors.

## 相关链接

## Related Links

* [Hermes Desktop 官方文档](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
[Hermes Desktop Official Documentation](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
* [官方平台支持说明](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support)
[Official Platform Support Notes](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support)
* [NousResearch/hermes-agent 上游仓库](https://github.com/NousResearch/hermes-agent)
[NousResearch/hermes-agent Upstream Repository](https://github.com/NousResearch/hermes-agent)
