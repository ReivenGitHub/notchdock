# Architecture

NotchDock is a macOS accessory application. Swift Package Manager builds the executable; scripts assemble a `.app` bundle with a property list, icon, and signature. There are no third-party runtime dependencies.

| Component | Responsibility |
| --- | --- |
| AppDelegate | Service ownership, menu bar, settings, hotkey, and application lifetime. |
| PanelController | Nonactivating NSPanel, display placement, hover timing, pinning, and resizing. |
| DisplayService | Live display choices, stable CoreGraphics UUIDs, and disconnected-display fallback. |
| HotKeyController / ShortcutRecorder | Validated Carbon hotkeys, temporary unregistering during recording, and conflict feedback. |
| PanelState / Preferences | Observable presentation state and saved preferences. |
| MediaService | Selected-player polling and controls via a serialized osascript worker. |
| ShelfStore / QuickLookController | References, bookmarks, file picker, drag handling, explicit copy actions, native previews, and persistence. |
| FocusStore | UI clock, migration, persistence, and completion around FocusArchive. |
| BatteryService | IOKit power source snapshot every 30 seconds. |
| NotchDockCore | Focus state machine/history, shortcut validation, shelf policy, and display geometry. |

## Window

The panel physically shrinks when collapsed so an invisible expanded window does not block the desktop. It floats at status-bar level, joins Spaces and full-screen spaces, and does not activate the application merely on hover. The shortcut can give it keyboard focus. Expanded controls sit below `NSScreen.safeAreaInsets.top`; auxiliary screen areas estimate the camera housing width.

Idle, activity, and expanded geometry share the same screen top and center. On a physical notch, idle draws no content; the transparent window uses the camera width plus a two-point hover/drop lip below it. The camera cutout cannot display content. Activity wings keep a dedicated camera-width gap, and expanded controls sit below the safe area. Files on the shelf do not count as activity. Non-notched screens retain a visible 120 × 28 point handle. Disabling quiet idle restores the visible compact panel.

While blended into the notch, local/global AppKit pointer monitors provide hover, click, and drag activation even if transparent pixels pass events to another app. They observe mouse movement/drag/click only, never keyboard input, and do not consume events. They are removed at shutdown. See [Apple's event-monitor documentation](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html).

One panel uses Automatic (first notched screen, then primary), the primary display, or a selected display UUID. Unplugging a selected screen temporarily falls back to Automatic while preserving the saved choice. Display-change and wake notifications reposition it. Reduce Motion disables resize animation. Text editing prevents automatic collapse until the panel loses keyboard focus. Full-screen and physical display behavior need the checks in [TESTING.md](TESTING.md).

## Music

Apple Music and Spotify are explicit integrations. The selected player must already be running for polling; background polling never launches it. After opt-in, polling runs every two seconds while expanded and every six seconds while collapsed to drive the activity indicator. Errors suspend polling until Retry or a new opening, and clear the active indicator. Disabling music resets the track and stops polling.

The scripts contain fixed commands and a two-value player enum. No filename, track title, clipboard, or arbitrary user text is evaluated as code. Process launches `/usr/bin/osascript` without a shell. A background serial queue executes it with AppleScript and helper-process timeouts. Connection versions discard stale responses after a player change.

macOS owns consent. The bundle declares an Automation purpose string and an Apple Events entitlement for Developer ID signing. No Accessibility or Screen Recording permission is requested.

## File references

Removing a shelf item never deletes its source file. The shelf accepts existing local file URLs and folders, deduplicates normalized paths, and holds at most 24. Bookmarks help locate moved files between launches; unavailable items stay visible and removable. Bookmark recovery is not guaranteed after deletion or remote-volume changes. Symlink aliases with different paths are not deduplicated by inode.

State is JSON written atomically under Application Support. The app stores paths and bookmarks, not file contents. It is not sandboxed. A Mac App Store port needs a separate sandbox and security-scoped bookmark lifecycle, plus a media integration review.

## Timer

A running timer stores a deadline instead of decrementing a counter, so delayed ticks and sleep do not extend the session. Pause saves remaining duration. Focus, short break, and long break share this state machine. Duration changes apply on the next start or to idle timers; active sessions are preserved.

FocusArchive wraps the current session, its mode and UUID, and up to 200 completions. A completion is recorded once with its deadline date, so a late wake or relaunch attributes it to the correct day. Daily totals use the local calendar and only completed focus sessions. Breaks and canceled sessions do not increase focus totals. An expired timer restored on launch shows complete without replaying a historical sound. Manual system-clock changes can affect an active deadline.

The new `focus-state.json` restores a valid legacy `focus.json` when no new archive exists. Both use atomic writes. History is local and bounded; there is no remote sync or notification scheduler.

## Platform references

- [Apple: NSScreen safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets)
- [Apple: NSPanel](https://developer.apple.com/documentation/appkit/nspanel)
- [Apple: Automation purpose string](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription)
- [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)
- [GitHub: checkout](https://github.com/actions/checkout)
- [GitHub: upload-artifact](https://github.com/actions/upload-artifact)
