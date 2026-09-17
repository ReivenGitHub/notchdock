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

## First-launch warning for downloaded builds

The current GitHub build has an ad-hoc signature and no Apple notarization ticket. The “NotchDock Not Opened” verification alert can therefore appear on a recipient's Mac even when the compilation and signature-structure checks pass.

The [README](../README.md#if-macos-says-notchdock-not-opened) explains Apple's per-app approval flow. Instructions are based on [Apple Support](https://support.apple.com/en-us/102445).

Passing `codesign --verify` establishes bundle signature integrity; it does not provide a Developer ID identity or an Apple notarization result. Removing the need for this approval in future releases requires an appropriate Developer ID signature and successful notarization. A source-only change cannot supply the owner's signing certificate.

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
