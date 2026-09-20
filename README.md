# NotchDock

**A little space. A clearer day.**

A native macOS notch companion with music controls, a file shelf, and a focus timer. Built with SwiftUI and AppKit, with no third-party runtime dependencies. Inspired by the idea behind NotchNook; this is an independent implementation with its own name, interface, and code. It is not affiliated with NotchNook or lo.cafe.

![NotchDock interface design preview](docs/preview.svg)

> **Early version · 0.3.0.** See [recorded validation results](docs/VALIDATION.md) and the [macOS build workflow](https://github.com/ReivenGitHub/notchdock/actions/workflows/macos.yml) for actual build status. Native interaction and hardware testing remain separate from compilation. The image above illustrates the original design, not a current app screenshot.

## What it does

| Feature | Behavior |
| --- | --- |
| Quiet idle notch | Blends into the real camera notch when idle, with no extra visible bar or icons. Hover or click to open; pin to keep open. |
| Activity indicators | A running or paused timer, or playing music, adds small indicators beside the camera. Stored files do not keep it expanded. |
| Music & album covers | Apple Music or Spotify controls, track/artist/album details, progress, and real cover art in Overview and beside the notch while playing. |
| Files Tray | Up to 24 files/folders, a dedicated drop target, drag in/out, search, sorting, Quick Look, copy file/path, and Finder actions. |
| AirDrop | A separate drop target opens Apple's recipient picker. Also available from each file's menu or the menu bar. |
| Mirror | A live camera preview with horizontal flip and an off button. Camera stops when you leave Mirror or close the panel. |
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

**[Download NotchDock 0.3 for Apple silicon and Intel](https://github.com/ReivenGitHub/notchdock/actions/runs/35225569221/artifacts/10498529932)** — native builds and all 49 checks passed. See [verification details](docs/VALIDATION.md). The artifact expires October 1, 2026.

Unzip the download and the included app ZIP. Quit the old app before replacing it in Applications; existing shelf references and timer state are preserved.

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
- **Music:** select a player in Settings, open it, then click Connect music and approve macOS Automation access. Playing music shows its cover beside the physical notch, including while a timer occupies the other side. Overview shows the larger cover and album name. If the player supplies no cover, a music placeholder and retry action appear; there is no guessed album search. Disable the integration in Settings at any time.
- **Files:** drag toward the notch to open Files. Drop on **Files Tray** to keep references or on **AirDrop** to choose a recipient. Search by name, sort, preview with the eye button, and drag cards out. Right-click a card to AirDrop, copy, open, reveal, or remove it. Originals stay in place.
- **AirDrop:** dropping files opens Apple's sharing window; you choose the recipient there. Click the target or use the menu bar to choose files instead. Wi-Fi, Bluetooth, receiver discoverability, and supported files are handled by macOS. AirDropped files are not also added to the tray.
- **Mirror:** click the Mirror tab or choose Open Mirror from the menu bar. Approve camera access if asked. Mirror stays open until you change tabs or close it, and can be flipped horizontally. The camera stops on exit, sleep, or session deactivation; after sleep, click Start mirror to resume.
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

NotchDock has no accounts, analytics, or tracking. It reads battery status and, only when music is enabled, the selected player's metadata through Apple Events. Spotify album artwork is fetched over HTTPS from the image URL supplied by Spotify, restricted to Spotify image CDN domains. These requests have no cookies, stored credentials, or persistent network cache. Titles and artists are not sent to an album-search service. Music artwork is read locally through a temporary file that is deleted after loading. The small decoded-cover cache is in memory only.

Mirror uses video input only while requested and visible. It does not save photos or recordings, access the microphone, or transmit camera frames. AirDrop hands selected file references to Apple's sharing service, and you select the recipient in macOS. The app does not read clipboard history, capture the screen, or use private MediaRemote APIs.

Shelf references, the current timer, and up to 200 completed sessions are stored under `~/Library/Application Support/NotchDock/`; settings use the `app.notchdock.desktop` user defaults domain. Version 0.2 restores the older timer file on first upgrade. Copy actions write to the clipboard only when requested. The app is not App Sandbox enabled. See the [architecture notes](docs/ARCHITECTURE.md) for file access details.

## License

[MIT](LICENSE). NotchNook, Apple Music, and Spotify names belong to their respective owners.
