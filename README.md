# HDFI — Hermes Desktop for Intel (macOS x86_64)

**Unofficial** build and release pipeline for [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent) on **macOS Intel (x86_64)**.

Official public macOS installers are **arm64-only**. Nous Research lists **macOS on Intel processors** as [unsupported](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support). Community verification shows the Electron desktop app still builds as `x86_64` from unmodified upstream source ([issue #60054](https://github.com/NousResearch/hermes-agent/issues/60054)). HDFI packages that path into a reproducible project with scripts and CI.

> Not affiliated with Nous Research. Not the same project as community [Hermes One](https://github.com/fathah/hermes-desktop) (`fathah/hermes-desktop`).

## What you get

| Artifact | Description |
|----------|-------------|
| `Hermes-*-mac-x64.dmg` | Electron desktop shell installer (primary) |
| `Hermes-*-mac-x64.zip` | Same app as zip |
| Optional Setup `.app` | Tauri bootstrap installer (best-effort; DMG may fail) |

Config and agent data use the normal Hermes layout: `~/.hermes`.

## Quick start (Intel Mac)

### Prerequisites

- macOS 12+ on **Intel (x86_64)**
- [Xcode Command Line Tools](https://developer.apple.com/xcode/)
- **Node.js** `^20.19` or `>=22.12` (22 LTS recommended)
- **Python** `>=3.11` (for the agent runtime Hermes Desktop manages)
- `git`, `codesign`, `lipo`, `file`

If Homebrew is not writable, install Node into your home directory (example):

```bash
NODE_VER=22.17.0
curl -fsSL "https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-darwin-x64.tar.gz" \
  | tar -xz -C "$HOME/.local"
export PATH="$HOME/.local/node-v${NODE_VER}-darwin-x64/bin:$PATH"
node -v   # v22.17.0
```

### Build

```bash
git clone --recurse-submodules <this-repo-url> HDFI
cd HDFI

./scripts/setup-deps.sh
./scripts/pin-upstream.sh          # init submodule if needed
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh            # required without Apple Developer ID
```

Outputs land in `dist/`.

### Install & Gatekeeper

Unsigned / ad-hoc signed builds may be blocked by macOS:

```bash
# After copying Hermes.app to /Applications:
xattr -cr /Applications/Hermes.app
# Or open once via right-click → Open
```

Verify architecture:

```bash
file /Applications/Hermes.app/Contents/MacOS/Hermes
# expect: Mach-O 64-bit executable x86_64
```

## Project layout

```
HDFI/
├── upstream/                 # git submodule → NousResearch/hermes-agent
├── scripts/                  # pin, setup, build, sign, verify
├── docs/BUILD.md             # detailed build handbook
├── .github/workflows/        # CI + release
└── dist/                     # local build output (gitignored)
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup-deps.sh` | Check toolchain (Node, Python, Xcode CLT, …) |
| `scripts/pin-upstream.sh` | Init/update submodule; optional pin to ref |
| `scripts/build-desktop-mac-x64.sh` | Build Electron Desktop for `mac-x64` |
| `scripts/build-bootstrap-mac-x64.sh` | Optional Tauri Setup for `x86_64-apple-darwin` |
| `scripts/sign-adhoc.sh` | Ad-hoc codesign (`codesign -s -`) |
| `scripts/verify-mac-x64.sh` | Assert x86_64 + write `dist/SHA256SUMS` |

Pin or upgrade upstream:

```bash
./scripts/pin-upstream.sh v1.2.3          # tag or commit
./scripts/pin-upstream.sh                 # use currently recorded submodule SHA
```

## CI

- **`build-mac-x64.yml`** — build on push/PR/`workflow_dispatch`, upload artifacts
- **`release.yml`** — on tag `v*`, build and attach files to a GitHub Release

CI may run on Apple Silicon runners and **cross-compile** Electron for `--x64`. Always re-verify `file`/`lipo` output; smoke-test on a real Intel Mac before relying on a release.

## Security

- Prefer artifacts from **your** CI or a local build; check `SHA256SUMS`.
- Ad-hoc signed builds are **not** notarized. Do not treat them like official signed releases.
- Upstream agent can run tools and access files — same trust model as official Hermes.

## License

MIT (see [LICENSE](./LICENSE)). Upstream Hermes Agent is MIT-licensed; copyright remains with its authors.

## References

- [Hermes Desktop docs](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
- [Platform support](https://hermes-agent.nousresearch.com/docs/getting-started/platform-support)
- [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)
- [Intel artifact request / local proof](https://github.com/NousResearch/hermes-agent/issues/60054)
