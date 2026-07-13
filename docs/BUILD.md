# Building Hermes Desktop for macOS Intel (x86_64)

This handbook covers local builds on an Intel Mac and how CI produces the same artifacts.

## Architecture notes

| Piece | Location | Role |
|-------|----------|------|
| Electron shell | `upstream/apps/desktop` | Chat UI, settings, packaging |
| Shared TS | `upstream/apps/shared` | Workspace package `@hermes/shared` |
| Agent runtime | installed into `~/.hermes` at first run / via CLI | Python agent + `hermes serve` |
| Bootstrap Setup | `upstream/apps/bootstrap-installer` | Optional Tauri first-run installer |

Primary deliverable is the **Desktop** Electron app. Bootstrap is best-effort.

## Environment

### Required tools

```bash
./scripts/setup-deps.sh
```

| Tool | Requirement |
|------|-------------|
| Node.js | `^20.19.0` or `>=22.12.0` (22 LTS recommended) |
| npm | ships with Node |
| Python | `>=3.11` (agent; Desktop may bootstrap a venv) |
| Xcode CLT | `xcode-select -p` must succeed |
| git, file, lipo, codesign, shasum | base system / CLT |

Install Node on macOS (examples):

```bash
# Homebrew
brew install node@22

# or nvm
nvm install 22
nvm use 22
```

### Electron download / mirrors

If GitHub is slow or blocked when fetching Electron:

```bash
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
```

`@electron/get` still verifies SHASUMS against the mirror host. Prefer a mirror you trust, or leave unset to use the default.

### Code signing

| Mode | When | Env |
|------|------|-----|
| Ad-hoc (default local) | No Apple Developer ID | `CSC_IDENTITY_AUTO_DISCOVERY=false`, then `./scripts/sign-adhoc.sh` |
| Developer ID | You have certs | Set `CSC_LINK`, `CSC_KEY_PASSWORD`; optional notarization `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID` |

Without notarization, users may need:

```bash
xattr -cr /Applications/Hermes.app
```

## Local build (recommended on Intel)

```bash
# From repo root
git submodule update --init --recursive   # or ./scripts/pin-upstream.sh
./scripts/setup-deps.sh
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
./scripts/sign-adhoc.sh
```

### What the desktop build does

1. `npm install --workspace apps/desktop` (and workspace resolution for `apps/shared`) from the **upstream monorepo root**
2. `npm run build --workspace apps/desktop` — Vite renderer + Electron main bundle + stage `node-pty`
3. `npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac --x64 dmg zip --publish=never`

Artifacts are copied to `dist/`:

- `Hermes-<version>-mac-x64.dmg`
- `Hermes-<version>-mac-x64.zip`
- `Hermes.app` (when present under `release/mac` or `release/mac-x64`)
- `SHA256SUMS` (from verify script)

### Manual equivalent (upstream root)

```bash
cd upstream
npm install --workspace apps/desktop
npm run build --workspace apps/desktop
export CSC_IDENTITY_AUTO_DISCOVERY=false
npm_config_arch=x64 npm run builder --workspace apps/desktop -- --mac --x64 --publish=never
file apps/desktop/release/mac/Hermes.app/Contents/MacOS/Hermes
# or: release/mac-x64/Hermes.app/...
```

## Optional: Bootstrap installer

```bash
./scripts/build-bootstrap-mac-x64.sh
```

Uses Tauri target `x86_64-apple-darwin`. Requires a Rust toolchain (`rustup target add x86_64-apple-darwin` if cross-building).

If DMG packaging fails (seen on some Intel hosts), the script zips the `.app` instead.

## Verification checklist

```bash
./scripts/verify-mac-x64.sh
```

Must pass:

1. Main binary is **only** `x86_64` (not arm64-only)
2. `node-pty` payload includes `darwin-x64` when staged inside the app
3. `dist/SHA256SUMS` lists all shipped files

Smoke test:

1. Launch `dist/Hermes.app` (or install from DMG)
2. Confirm app opens (Gatekeeper / `xattr` if needed)
3. Complete or skip provider onboarding
4. Send a short chat if a model/API is configured
5. Confirm `~/.hermes` is used (same as CLI)

## Upgrading upstream

```bash
# Pin to a tag or commit
./scripts/pin-upstream.sh <tag-or-sha>

# Rebuild and re-verify
./scripts/build-desktop-mac-x64.sh
./scripts/verify-mac-x64.sh
```

Commit the submodule pointer change after a successful build:

```bash
git add upstream
git commit -m "chore: pin upstream hermes-agent to <ref>"
```

Intel is **unsupported** by Nous Research — re-run full verify after every pin.

## CI notes

Workflows live under `.github/workflows/`.

- Builds use Node 22 and recursive submodules.
- Runners may be arm64 (`macos-14` / `macos-15`). Electron Builder can still emit `--x64` by downloading the x64 Electron runtime.
- Prefer smoke-testing CI artifacts on a real Intel machine before wide distribution.
- Optional repository variable: `ELECTRON_MIRROR`.

## Troubleshooting

### Build stuck downloading Electron

Clear cache and set a mirror:

```bash
rm -f "$HOME/Library/Caches/electron"/electron-*.zip
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
./scripts/build-desktop-mac-x64.sh
```

### `node-pty` missing for darwin-x64

`verify-mac-x64.sh` fails if prebuilds/build output for x64 are absent. From upstream:

```bash
cd upstream
npx electron-rebuild -f -w node-pty -v "$(node -p "require('apps/desktop/package.json').devDependencies.electron.replace(/^[^0-9]*/, '')")"
# then re-run desktop build with npm_config_arch=x64
```

Exact rebuild flags may vary with Electron version; prefer node-pty prebuilds when available.

### App is arm64 after build

Ensure you passed `--x64` and `npm_config_arch=x64`. Do not run a default host-only pack on an arm64 machine without those flags if the goal is Intel artifacts.

### App won't open (damaged / unidentified developer)

```bash
codesign --force --deep --sign - /path/to/Hermes.app
xattr -cr /path/to/Hermes.app
```

### Workspace install fails

Install from the **hermes-agent monorepo root** (`upstream/`), not only `apps/desktop`, so workspaces resolve.

## Out of scope for HDFI v1

- Official Nous Research release channel
- Universal (arm64 + x64) fat binaries
- Windows / Linux packaging
- Changes to agent learning / skills logic
