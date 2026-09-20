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
| ArtworkLoader / AlbumArtwork | Local Music cover extraction, bounded Spotify image fetches, thumbnail decoding, in-memory caching, and shared cover UI. |
| AirDropService | Native NSSharingService recipient picker, chosen-file validation, and sharing completion/cancellation. |
| MirrorService / MirrorView | Camera permission, serialized video capture, mirrored preview, and visible-only lifetime. |
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

Apple Music, Spotify, Chrome YouTube, and Safari YouTube are explicit integrations. Automatic mode checks only supported apps that are already running, keeps the current source first for stability, and chooses playing media before a paused fallback. A specific source can be selected instead. Background polling never launches an app. After opt-in, polling runs every two seconds while expanded and every six seconds while collapsed to drive the activity indicator. Errors suspend polling until Retry or a new opening, and clear the active indicator. Disabling media resets the track and stops polling.

The native scripts contain fixed commands and a finite source enum. Browser integration passes one of four fixed JavaScript programs—metadata, play/pause, previous, or next—as an osascript argument. It enumerates tabs whose URL contains `youtube.com/`; non-YouTube tabs never execute the script. Page values are stripped of newlines and the unit-separator protocol character before parsing. No filename, track title, clipboard, or arbitrary user text is evaluated as code. Process launches `/usr/bin/osascript` without a shell. A background serial queue executes it with AppleScript and helper-process timeouts. Connection versions discard stale responses after a source change.

macOS has no supported public API for reading every other application's system Now Playing state. NotchDock therefore avoids the private MediaRemote framework and reports only integrations it can verify. Chrome and Safari require the user to enable JavaScript from Apple Events in the Developer menu and approve Automation. A disabled setting produces recovery guidance. Unsupported websites and desktop players remain outside Automatic detection.

macOS owns consent. The bundle declares an Automation purpose string and an Apple Events entitlement for Developer ID signing. No Accessibility or Screen Recording permission is requested.

### Album artwork

Metadata includes a track identifier and player-supplied artwork URL. Artwork keys include the source, track, title, artist, album, and cover URL, but exclude progress and playing/paused state. A generation ticket prevents canceled or stale asynchronous loads from replacing the current cover. Changing sources, disabling media, or losing the track clears the cover. Failed covers are retried after 30 seconds, with an explicit reload action.

Music supplies `raw data of artwork 1`; the script checks the track identifier and metadata, receives values as process arguments, and writes to a private temporary directory. The file is removed after loading. No untrusted string is interpolated into script code. Spotify and YouTube supply artwork URLs. Only HTTPS on the matching provider allowlist is accepted, including redirects: Spotify CDNs (`scdn.co`, `spotifycdn.com`, `spotifycdn.net`) or YouTube/Google image CDNs (`ytimg.com`, `googleusercontent.com`). Providers cannot use each other's allowlist. The ephemeral URL session has no cookie store, credentials, or disk cache, caps downloads at 8 MiB, and uses timeouts. Images are decoded as thumbnails up to 512 pixels and cached in memory (16 covers).

The compact left wing shows album art whenever music is playing; an active timer can remain in the right wing. Expanded Overview also shows the album name. Missing artwork uses a labeled placeholder rather than another album's cover. Some streaming tracks/local Spotify files may not expose artwork.

## File references

Removing a shelf item never deletes its source file. The shelf accepts existing local file URLs and folders, deduplicates normalized paths, and holds at most 24. Bookmarks help locate moved files between launches; unavailable items stay visible and removable. Bookmark recovery is not guaranteed after deletion or remote-volume changes. Symlink aliases with different paths are not deduplicated by inode.

State is JSON written atomically under Application Support. The app stores paths and bookmarks, not file contents. It is not sandboxed. A Mac App Store port needs a separate sandbox and security-scoped bookmark lifecycle, plus a media integration review.

Files Tray and AirDrop share one root `DropDelegate`. `FileDropLayout` maps the AirDrop target using the same dimensions as the view, so a single drop cannot both share and add a reference. All other file drops route to the tray, including at the compact notch. Provider loading is shared by both services. AirDrop receives only existing local file URLs, and uses `NSSharingService(named: .sendViaAirDrop)`; macOS owns discovery and recipient selection. The service remains retained while sharing, and an interaction hold prevents the panel closing during the picker. Original files are never moved or deleted.

## Mirror

Opening the Mirror tab requests camera authorization if needed, then starts a video-only AVCaptureSession on a private serial queue. AVCaptureVideoPreviewLayer renders directly; there is no file output, audio input, screenshot, or frame-upload path. Horizontal mirroring uses the preview connection's mirroring support. Denied access, unavailable cameras, and interrupted sessions have visible recovery controls.

Expanded state and the selected tab control the capture lifetime. Generation checks discard permission/start callbacks after a tab change or close, while queued stop operations release inputs. The Mirror tab suppresses hover auto-close until the user changes tabs or explicitly closes. Sleep, display sleep, and session deactivation stop capture and require an explicit restart if Mirror remains open. App termination also stops the session. The bundle includes NSCameraUsageDescription and the camera entitlement for hardened-runtime signing.

## Timer

A running timer stores a deadline instead of decrementing a counter, so delayed ticks and sleep do not extend the session. Pause saves remaining duration. Focus, short break, and long break share this state machine. Duration changes apply on the next start or to idle timers; active sessions are preserved.

FocusArchive wraps the current session, its mode and UUID, and up to 200 completions. A completion is recorded once with its deadline date, so a late wake or relaunch attributes it to the correct day. Daily totals use the local calendar and only completed focus sessions. Breaks and canceled sessions do not increase focus totals. An expired timer restored on launch shows complete without replaying a historical sound. Manual system-clock changes can affect an active deadline.

The new `focus-state.json` restores a valid legacy `focus.json` when no new archive exists. Both use atomic writes. History is local and bounded; there is no remote sync or notification scheduler.

## Platform references

- [Apple: NSScreen safeAreaInsets](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets)
- [Apple: NSPanel](https://developer.apple.com/documentation/appkit/nspanel)
- [Apple: Automation purpose string](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription)
- [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)
- [Apple: NSSharingService](https://developer.apple.com/documentation/appkit/nssharingservice)
- [Apple: Camera authorization](https://developer.apple.com/documentation/avfoundation/requesting-authorization-to-capture-and-save-media)
- [Apple: AVCaptureVideoPreviewLayer](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer)
- [GitHub: checkout](https://github.com/actions/checkout)
- [GitHub: upload-artifact](https://github.com/actions/upload-artifact)
