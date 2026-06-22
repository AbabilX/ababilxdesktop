# AbabilX Desktop — Downloads

Public release repo for AbabilX desktop installers.

**Download:** [GitHub Releases](https://github.com/AbabilX/ababilxdesktopfile/releases/latest)

## Installers

| Platform | File |
|----------|------|
| Windows | `.msi` or `.exe` |
| macOS Apple Silicon | `aarch64` `.dmg` |
| macOS Intel | `x86_64` `.dmg` |
| Linux | `.AppImage` or `.deb` |

## How releases are published

Installers are built in the **private** source repo and uploaded here automatically when a `v*` tag is pushed.

You can also upload builds manually to [AbabilX/ababilxdesktop](https://github.com/AbabilX/ababilxdesktop) if you prefer.

## Install guides

Full install steps, OS security bypass (SmartScreen / Gatekeeper), and build-from-source docs are in the private repo README (developer copy).

### Windows SmartScreen

**More info** → **Run anyway**

### macOS Gatekeeper

**System Settings → Privacy & Security → Open Anyway**, or:

```bash
xattr -cr /Applications/ababilxdesktop.app
```

### Linux AppImage

```bash
chmod +x ababilxdesktop_*.AppImage
./ababilxdesktop_*.AppImage
```

## Version check

The desktop app checks `GET /v1/api/check` on launch and prompts to download when a newer version is available.

Download URL points to this repo: `https://github.com/AbabilX/ababilxdesktopfile/releases/latest`
