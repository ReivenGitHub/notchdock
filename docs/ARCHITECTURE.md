# Architecture

NotchDock is a macOS accessory application. Swift Package Manager builds the executable; scripts assemble a `.app` bundle with a property list, icon, and signature. There are no third-party runtime dependencies.

| Component | Responsibility |
| --- | --- |
| AppDelegate | Service ownership, menu bar, settings, hotkey, and application lifetime. |
| PanelController | Nonactivating NSPanel, display placement, hover timing, pinning, and resizing. |
| PanelState / Preferences | Observable presentation state and saved preferences. |
| MediaService | Selected-player polling and controls via a serialized osascript worker. |
| ShelfStore | File references, bookmarks, file picker, drag handling, and persistence. |
| FocusStore | UI clock, persistence, and completion around FocusSession. |
| BatteryService | IOKit power source snapshot every 30 seconds. |
| NotchDockCore | Foundation-only focus state machine, shelf policy, and display geometry. |

## Window

The panel physically shrinks when collapsed so an invisible expanded window does not block the desktop. It floats at status-bar level, joins Spaces and full-screen spaces, and does not activate the application merely on hover. The shortcut can give it keyboard focus. Expanded controls sit below `NSScreen.safeAreaInsets.top`; auxiliary screen areas estimate the camera housing width.

One panel uses the first notched display when that preference is enabled, otherwise the primary display. Display-change and wake notifications reposition it. Reduce Motion disables resize animation. Full-screen and physical display behavior need the checks in [TESTING.md](TESTING.md).

## Music

Apple Music and Spotify are explicit integrations. The selected player must already be running for polling; background polling never launches it. Polling runs every two seconds only while expanded and after opt-in. Errors suspend polling until Retry or a new opening.

The scripts contain fixed commands and a two-value player enum. No filename, track title, clipboard, or arbitrary user text is evaluated as code. Process launches `/usr/bin/osascript` without a shell. A background serial queue executes it with AppleScript and helper-process timeouts. Connection versions discard stale responses after a player change.

macOS owns consent. The bundle declares an Automation purpose string and an Apple Events entitlement for Developer ID signing. No Accessibility or Screen Recording permission is requested.

## File references

Removing a shelf item never deletes its source file. The shelf accepts existing local file URLs and folders, deduplicates normalized paths, and holds at most 24. Bookmarks help locate moved files between launches; unavailable items stay visible and removable. Bookmark recovery is not guaranteed after deletion or remote-volume changes. Symlink aliases with different paths are not deduplicated by inode.

State is JSON written atomically under Application Support. The app stores paths and bookmarks, not file contents. It is not sandboxed. A Mac App Store port needs a separate sandbox and security-scoped bookmark lifecycle, plus a media integration review.

## Timer

A running timer stores a deadline instead of decrementing a counter, so delayed ticks and sleep do not extend the session. Pause saves remaining duration. Completion changes phase once. An expired timer restored on launch shows complete without replaying a historical sound. Manual system-clock changes can affect an active deadline.

## Platform references

- [Apple: NSScreen safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets)
- [Apple: NSPanel](https://developer.apple.com/documentation/appkit/nspanel)
- [Apple: Automation purpose string](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription)
- [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)
- [GitHub: checkout](https://github.com/actions/checkout)
- [GitHub: upload-artifact](https://github.com/actions/upload-artifact)
