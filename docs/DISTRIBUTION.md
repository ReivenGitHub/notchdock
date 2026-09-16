# Building and distribution

## Local build

```bash
bash scripts/build-app.sh native
open build/NotchDock.app
```

This assembles and ad-hoc signs `build/NotchDock.app`. It does not install, enable login, or change macOS security settings.

## Universal archive

```bash
bash scripts/package-app.sh universal
```

The script builds arm64 and x86_64, combines them using lipo, generates icons, signs, and archives with ditto. Output: `dist/NotchDock-macOS.zip` and `dist/SHA256SUMS.txt`. The internal ZIP preserves executable permissions through GitHub artifact download.

## Developer ID

For broad distribution use your own bundle ID, Developer ID Application certificate, and notarization. Keep credentials in your keychain or repository secrets, never in code.

With your identity and a `NotchDock` notarytool keychain profile already configured:

```bash
SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' bash scripts/package-app.sh universal
xcrun notarytool submit dist/NotchDock-macOS.zip --keychain-profile NotchDock --wait
xcrun stapler staple build/NotchDock.app
ditto -c -k --sequesterRsrc --keepParent build/NotchDock.app dist/NotchDock-macOS.zip
shasum -a 256 dist/NotchDock-macOS.zip > dist/SHA256SUMS.txt
spctl --assess --type execute --verbose build/NotchDock.app
```

The default workflow does not notarize, require signing secrets, or publish a GitHub Release. When changing the bundle ID, update the property list, validator, and privacy documentation together. Test Automation and login items from the final signed bundle. Different signing identities can require renewed macOS consent.
