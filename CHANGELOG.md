# Changelog

## 0.4.0 — Automatic media and YouTube

- Added Automatic detection across running Apple Music, Spotify, Google Chrome, and Safari, preferring an actively playing source over paused sources.
- Added YouTube and YouTube Music metadata in Chrome and Safari: title, channel/artist, album/site, progress, play/pause, previous/next when available, and player-supplied thumbnails.
- Added explicit Chrome and Safari source choices alongside Automatic, Apple Music, and Spotify.
- Kept browser automation opt-in: users enable JavaScript from Apple Events in the browser and approve macOS Automation. Only YouTube tabs are inspected.
- Extended the bounded artwork allowlist to YouTube/Google image CDNs without cookies, credentials, or persistent caching.
- Added browser-script, command, source-policy, and artwork-domain regression coverage (55 XCTest cases total).
- Continued to avoid Apple's private MediaRemote framework; unsupported apps and websites are not presented as detected media.

## 0.3.0 — Files Tray, AirDrop, Mirror, and album covers

- Added separate Files Tray and AirDrop drop targets, with a single drop router to avoid duplicate actions.
- Added native AirDrop recipient selection from drops, file context menus, a picker, and the menu bar.
- Added a live camera mirror with horizontal flip, explicit camera permission, off/retry controls, and shutdown when hidden, sleeping, or quitting. No microphone or recording.
- Added album artwork to the compact notch while music plays, including alongside an active timer, and artwork plus album name in Overview.
- Added local Music artwork extraction and bounded Spotify image downloads, in-memory caching, stale-result rejection, cancellation, and retry.
- Enlarged the expanded content area to accommodate the new tools while preserving the quiet idle notch.
- Added 14 portable regression cases and a macOS Music-script compilation check (49 XCTest cases total).

## 0.2.0 — Quiet notch and everyday tools

- Idle on a notched display now draws no extra bar, icons, or border outside the physical camera housing. A transparent hover/drop strip keeps it reachable.
- Added camera-safe side indicators for active/paused timers and playing music. An occupied file shelf does not count as live activity.
- Added opt-in music polling while collapsed, every six seconds, without launching the player.
- Added a custom shortcut recorder, conflict feedback, reset, and disable controls.
- Added selection of any connected display, persistent display identifiers, and reconnect fallback.
- Added shelf search, sorting, Quick Look previews, copy file/path, visible remove buttons, and removal of unavailable references.
- Added focus/short-break/long-break modes, custom durations, local completion history, and daily focus totals.
- Preserved legacy timers and display preferences; running and paused timers keep their duration after a settings change.
- Kept the panel open during search editing and reorganized settings into tabs.
- Added 16 regression tests for idle geometry, shortcut validation, and completion/history behavior (34 total).

## 0.1.0 — Initial implementation

- Added a notch-aware AppKit panel and SwiftUI interface with hover, pin, and keyboard controls.
- Added optional Apple Music and Spotify playback through application-owned AppleScript.
- Added a persistent file-reference shelf with duplicate handling, drag in/out, a picker, and Finder actions.
- Added a persistent deadline-based focus timer with completion feedback.
- Added battery status, display selection, login-item settings, and reduced-motion-aware resizing.
- Added icon generation, native and universal packaging scripts, and a macOS CI workflow.
- Added 18 core XCTest cases, static packaging checks, and platform verification documentation.

See [validation results](docs/VALIDATION.md) for checks actually performed. Compilation is separate from manual hardware testing and notarization.
