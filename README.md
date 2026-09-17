# NotchDock

**A little space. A clearer day.**

A native macOS notch companion with music controls, a file shelf, and a focus timer. Built with SwiftUI and AppKit, with no third-party runtime dependencies. Inspired by the idea behind NotchNook; this is an independent implementation with its own name, interface, and code. It is not affiliated with NotchNook or lo.cafe.

![NotchDock interface design preview](docs/preview.svg)

> **Early version · 0.2.0.** See [recorded validation results](docs/VALIDATION.md) and the [macOS build workflow](https://github.com/ReivenGitHub/notchdock/actions/workflows/macos.yml) for actual build status. Native interaction and hardware testing remain separate from compilation. The image above illustrates the original design, not a current app screenshot.

## What it does

| Feature | Behavior |
| --- | --- |
| Quiet idle notch | Blends into the real camera notch when idle, with no extra visible bar or icons. Hover or click to open; pin to keep open. |
| Activity indicators | A running or paused timer, or playing music, adds small indicators beside the camera. Stored files do not keep it expanded. |
| Music | Optional Apple Music or Spotify desktop controls, track details, progress, and compact activity status. |
| File shelf | Up to 24 files/folders, drag in/out, search, newest/name sorting, Quick Look, copy file/path, and Finder actions. |
| Focus & breaks | Custom focus, short-break, and long-break durations; pause/resume/reset; sound; saved state; today's completed focus totals. |
| Battery | Battery percentage and charging state; a desktop indicator on Macs without a battery. |
| Display support | Choose any connected display. Remembers the choice across reconnections; non-notched displays keep a small handle. |
| Keyboard | Record a custom global shortcut, reset to Option–Command–Space, or disable it. No Accessibility permission. |
| Settings | Idle and hover behavior, display, shortcut, session durations, completion behavior, music app, and launch at login. |

Files remain at their original locations. Removing a shelf item removes only its reference. The shelf restores after relaunch using local bookmarks. Music support is for the Apple Music and Spotify **desktop apps**; browser tabs and other players are not supported.

The physical camera cutout cannot display pixels. When idle on a notched Mac, NotchDock draws nothing outside it; a transparent two-point strip below it accepts hover and file drops. Controls appear beside or below the camera when active or expanded. Turn off **Settings → Notch → Blend into the hardware notch when idle** to keep a visible compact handle. Unpin and close the panel to return to idle.

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

### If macOS says “NotchDock” Not Opened

The GitHub build is ad-hoc signed and has not been notarized by Apple. macOS can therefore block its first launch with “Apple could not verify NotchDock is free of malware.”

If this is the build you downloaded from this repository and you choose to trust it:

1. Click **Done** in the warning.
2. Open **System Settings → Privacy & Security**.
3. Scroll to **Security**, find the entry for NotchDock, and click **Open Anyway**.
4. Confirm with **Open** and authenticate if macOS asks.

If the entry is missing, try opening the app once, then return to Privacy & Security. On a managed Mac, these controls may be restricted by the administrator.

This creates an exception for the app. It is not Apple notarization or a malware scan. See [Apple’s instructions](https://support.apple.com/en-us/102445). For a release that meets the normal Developer ID and notarization checks, follow the [distribution guide](docs/DISTRIBUTION.md).

## Use it

- **Open:** hover at the top center, click the compact panel, use the menu bar, or press **⌥⌘Space**.
- **Keep open:** click the pin. Click Close, press Escape while the panel has keyboard focus, or use the toggle shortcut to close it.
- **Music:** select a player in Settings, open it, then click Connect music and approve macOS Automation access. Disable the integration in Settings at any time.
- **Files:** drop files at the notch or on the expanded panel. Search by name; use the options menu to sort or remove unavailable references. The eye button opens Quick Look. Right-click to copy the file or path, open, reveal, or remove it. Originals stay in place.
- **Focus:** choose Focus, Short break, or Long break before starting. Set custom durations in Settings. Pause preserves remaining time; Reset cancels the session. Expired deadlines finish after wake or relaunch. Only completed focus sessions count toward today's totals.
- **Display & keyboard:** open Settings → Notch. Record a shortcut with Command, Option, or Control; Escape cancels recording. The menu bar works even when a shortcut is unavailable or disabled.
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

Shelf references, the current timer, and up to 200 completed sessions are stored under `~/Library/Application Support/NotchDock/`; settings use the `app.notchdock.desktop` user defaults domain. Version 0.2 restores the older timer file on first upgrade. Copy actions write to the clipboard only when requested. The app is not App Sandbox enabled. See the [architecture notes](docs/ARCHITECTURE.md) for file access details.

## License

[MIT](LICENSE). NotchNook, Apple Music, and Spotify names belong to their respective owners.
