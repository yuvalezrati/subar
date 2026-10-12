# Scripts

People who just want Subar don't need any of these: they download the `.pkg` from the [latest release](https://github.com/yuvalezrati/subar/releases/latest).

| Script | Who it's for | What it does |
|---|---|---|
| `build-app.sh` | Maintainer | Turns `subar.swift` into the release files in `dist/`: the `.pkg` installer, a `.zip` and `Subar.app`. GitHub Actions runs it when a version tag is pushed |
| `dev-install.sh` | Developers | Compiles `subar.swift` and runs it straight away, restarting it after each change. `./scripts/dev-install.sh uninstall` removes it |
| `get-subar.sh` | Terminal users | Downloads the latest release that `build-app.sh` produced and puts it in Applications. An alternative to the `.pkg` that skips the security warning |

You need the Xcode Command Line Tools to build: `xcode-select --install`.

## Publishing a release

Push a version tag and GitHub Actions builds and publishes it:

```bash
git tag v1.1.0 && git push origin v1.1.0
```

## Signing with an Apple Developer ID

With a paid Apple Developer account, the installer opens with no security warning. You need a *Developer ID Application* and a *Developer ID Installer* certificate. Create a notarization profile once with `xcrun notarytool store-credentials subar-notary`, then run:

```bash
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
INSTALLER_ID="Developer ID Installer: Your Name (TEAMID)" \
NOTARY_PROFILE="subar-notary" ./scripts/build-app.sh
```

## Terminal install

```bash
curl -fsSL https://raw.githubusercontent.com/yuvalezrati/subar/main/scripts/get-subar.sh | bash
```
