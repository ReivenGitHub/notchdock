# NotchDock

**A little space. A clearer day.**

A native macOS notch companion with music controls, a file shelf, and a focus timer. Built with SwiftUI and AppKit, with no third-party runtime dependencies. Inspired by the idea behind NotchNook; this is an independent implementation with its own name, interface, and code. It is not affiliated with NotchNook or lo.cafe.

![NotchDock interface design preview](docs/preview.svg)

> **Early version · 0.1.0.** See [recorded validation results](docs/VALIDATION.md) and the [macOS build workflow](https://github.com/ReivenGitHub/notchdock/actions/workflows/macos.yml) for actual build status. Native interaction and hardware testing remain separate from compilation. The image above is a design illustration, not an app screenshot.

## What it does

| Feature | Behavior |
| --- | --- |
| Expanding notch | Hover or click to open. Pin it to keep it open, or press Escape to close. |
| Music | Optional Apple Music or Spotify desktop controls, track details, and progress. |
| File shelf | Drop up to 24 local files or folders, drag them into other apps, open them, or reveal them in Finder. |
| Focus | 15, 25, and 50 minute sessions with pause, resume, reset, completion sound, and saved state. |
| Battery | Battery percentage and charging state; a desktop indicator on Macs without a battery. |
| Display support | Adapts to a hardware notch, with a compact top-center panel on other displays. |
| Keyboard | Option–Command–Space toggles the panel without Accessibility permission. |
| Settings | Hover behavior, preferred display, music app, completion sound, and launch at login. |

Files remain at their original locations. Removing a shelf item removes only its reference. The shelf restores after relaunch using local bookmarks. Music support is for the Apple Music and Spotify **desktop apps**; browser tabs and other players are not supported.

## Get it running on your Mac

Requires **macOS 13 Ventura or newer** and **Xcode 15+ or compatible Command Line Tools with Swift 5.9+** for a source build. The packaging script supports Apple silicon and Intel.

1. Download this repository using **Code → Download ZIP**, then unzip it.
2. If you need Apple's developer tools, open Terminal and run `xcode-select --install`.
3. Open Terminal in the unzipped project folder, then run:

```bash
bash scripts/build-app.sh
open build/NotchDock.app
```

You can also run `Build-NotchDock.command` from the project folder. The app lives in the menu bar and at the top of your display, so there is no Dock icon. On first launch, the panel stays pinned so you can explore it.

Drag `build/NotchDock.app` into **Applications** to keep it. Enable launch at login after moving it there.

### Download a GitHub build

Open [Actions](https://github.com/ReivenGitHub/notchdock/actions/workflows/macos.yml), choose a successful **Build NotchDock for macOS** run, and download its **NotchDock-macOS** artifact. Unzip the download and the included `NotchDock-macOS.zip` to get the `.app`. The workflow builds both architectures and includes a SHA-256 checksum. It does not automatically publish a Release.

Local and CI builds are ad-hoc signed, not Apple notarized. A downloaded build may need explicit approval in **System Settings → Privacy & Security**. For broad distribution, use your Developer ID and the [signing instructions](docs/DISTRIBUTION.md).

## Use it

- **Open:** hover at the top center, click the compact panel, use the menu bar, or press **⌥⌘Space**.
- **Keep open:** click the pin. Click Close, press Escape while the panel has keyboard focus, or use the toggle shortcut to close it.
- **Music:** select a player in Settings, open it, then click Connect music and approve macOS Automation access. Disable the integration in Settings at any time.
- **Files:** drop files on the compact or expanded panel. Drag a card out to another app. Right-click to open, reveal, or remove it. Add also opens a file picker.
- **Focus:** choose a duration before starting. Pause preserves remaining time; Reset stops the session. Expired deadlines finish after wake or relaunch.
- **Quit:** choose Quit NotchDock from the menu bar menu.

If another app has registered the global shortcut, Settings reports it as unavailable; the menu bar remains usable.

## Develop

Open `Package.swift` in Xcode, or use Terminal:

```bash
python3 scripts/validate-project.py  # Static packaging checks
swift test --parallel               # Core tests; compiles the executable on macOS
bash scripts/package-app.sh universal
```

Test Automation and login items from the packaged `.app`. A raw `swift run` executable lacks the required bundle metadata. The Foundation-only core can also be tested on Linux with Swift 5.9+; the app target is included only on macOS.

- [Architecture and design decisions](docs/ARCHITECTURE.md)
- [Tests, manual QA, and current limits](docs/TESTING.md)
- [Recorded validation](docs/VALIDATION.md)
- [Signing and distribution](docs/DISTRIBUTION.md)
- [Implementation log and next steps](docs/DEVELOPMENT.md)
- [Changelog](CHANGELOG.md)

## Privacy

NotchDock has no accounts, analytics, tracking, or network code. It reads local battery status and, only when enabled, the selected player's metadata through Apple Events. It does not read clipboard history, capture the screen, or use private MediaRemote APIs.

Shelf references and the focus session are stored under `~/Library/Application Support/NotchDock/`; settings use the `app.notchdock.desktop` user defaults domain. The app is not App Sandbox enabled. See the [architecture notes](docs/ARCHITECTURE.md) for file access details.

## License

[MIT](LICENSE). NotchNook, Apple Music, and Spotify names belong to their respective owners.
