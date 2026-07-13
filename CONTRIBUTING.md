# Contributing to hermes-desktop-intel (HDFI)

非官方、由社区维护的 **Hermes Desktop macOS Intel (x86_64)** 构建/打包仓库。
与 Nous Research 无隶属关系。

## 范围

本仓库只负责**打包与发布**，不包含 Hermes 桌面应用本身的源码。
应用源码来自子模块 `upstream/`（NousResearch/hermes-agent），通过
`scripts/pin-upstream.sh` 固定到某个 release tag 或 commit。

请勿在此仓库提交上游应用的代码改动——请向上游提交 PR。

## 本地构建

```bash
git submodule update --init --recursive
./scripts/setup-deps.sh
./scripts/build-desktop-mac-x64.sh      # 产出 dist/Hermes-*-mac-x64.*
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh                 # 仅本地 ad-hoc 签名，非公证
```

详见 [`docs/BUILD.md`](docs/BUILD.md)。

## 更新上游版本

```bash
./scripts/pin-upstream.sh <tag-or-commit>   # 更新子模块指针
git add upstream upstream-ref.txt
git commit -m "chore: pin upstream to <ref>"
```

## Commit 规范

- 使用 Conventional Commits 风格前缀：`docs:`、`fix:`、`feat:`、`chore:`、`build:`。
- 不要删除 `.github/workflows/` —— 它们是构建与发布流水线。
- 修改构建脚本后请确认本地可构建再开 PR。

## 提交身份

GitHub 提交身份统一使用账号的 no-reply 邮箱
（`80162038+Cooper1896@users.noreply.github.com`），
避免历史作者分裂。
