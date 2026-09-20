# Verification

See [VALIDATION.md](VALIDATION.md) for results actually observed. A checked-in test or workflow is not a passing result. The initial authoring workspace runs Linux without Swift or the macOS SDK.

## Automated checks

`python3 scripts/validate-project.py` checks packaging inputs, shell syntax, property lists, links, and SVG syntax. It does not type-check Swift or run the app.

`swift test --parallel` runs 55 XCTest cases on macOS (54 portable cases and one macOS-only script compilation case):

- Nine timer cases cover pause/resume, sleep deadlines, one-shot completion, restart, repeated start, reset, JSON restoration, formatting, invalid durations, and backward clock movement.
- Five shelf cases cover duplicates, existing items, URL rejection, capacity, and normalized paths.
- Eight geometry cases cover notch clearance, quiet idle width, missing-hardware fallback, anchoring, negative display coordinates, and narrow-screen containment.
- Eight archive cases cover one-shot completion across relaunch, pause identity, cancellation, excluding breaks, midnight boundaries, late clicks, legacy restoration, and bounded history.
- Four shortcut cases cover the default binding, modifier requirements, invalid keycodes/flags, and persistence of custom and disabled shortcuts.
- Ten media/artwork cases cover metadata and album fields, paused tracks, identity changes, malformed results, numeric handling, allowed/blocked artwork URLs, and stale or canceled image results.
- Four drop-routing cases cover the AirDrop target, tray/gap/header/card areas, compact/other-tab fallback, and changing notch geometry.
- One macOS case compiles the actual Music metadata and artwork scripts against the installed dictionary without executing them or requesting Automation permission. Spotify requires separate live-app verification.
- Six browser-media cases cover YouTube/Google artwork allowlists, provider isolation, fixed metadata fields, YouTube-only tab filtering, disabled-JavaScript recovery markers, and fixed playback commands. The macOS script test also compiles Safari automation and Chrome automation when Chrome is installed on the runner.

The macOS workflow compiles the executable, runs the tests, builds arm64 and x86_64 binaries, combines them, verifies signature structure, and packages an artifact. A successful build does not confirm interactive integration behavior.

## Manual Mac checklist

Use the bundled `.app`, not a bare command-line executable.

- [ ] Controls remain below a hardware notch; the fallback works on a non-notched display.
- [ ] With no live activity, unpin/close: no bar, icons, or border protrude outside the physical notch. Hover/drop just below it opens the panel.
- [ ] Start/pause/reset a focus timer and play/pause/quit the selected player. Activity wings appear/disappear; a populated shelf alone stays quiet. Background music changes may take six seconds.
- [ ] Turn quiet idle off/on and confirm both the visible handle and quiet notch remain reachable.
- [ ] Hover opens, pointer exit closes, pin prevents automatic closing, and closing restores desktop clicks.
- [ ] ⌥⌘Space, menu bar fallback, and Escape with panel focus work.
- [ ] Record a custom shortcut, reject plain typing keys, cancel with Escape, close Settings during capture, test a shortcut conflict, reset, disable, and relaunch.
- [ ] Settings opens normally; closing it leaves the app running.
- [ ] Spaces, full screen, sleep/wake, and display reconnection preserve placement.
- [ ] Select a specific secondary monitor, unplug/reconnect it, and confirm fallback and restoration, including negative display coordinates.
- [ ] Reduce Motion disables window animation.
- [ ] VoiceOver identifies tabs, playback, timer, files, and settings controls.
- [ ] Apple Music: consent, denied consent, retry, playback controls, no track, and player quit.
- [ ] Spotify: repeat the music checks; switch players during a pending poll.
- [ ] Automatic: play one supported source at a time, then multiple sources. Playing media wins over paused media; the displayed source and controls match the selected track.
- [ ] Chrome and Safari YouTube: disabled JavaScript-from-Apple-Events guidance, Automation consent/denial, ordinary YouTube, YouTube Music, multiple tabs, paused tabs, play/pause, previous/next availability, browser quit, and tab close.
- [ ] Confirm non-YouTube browser tabs are never inspected and unsupported players do not appear as detected. Check that switching from a YouTube source to native playback clears stale browser artwork.
- [ ] Music and Spotify: real cover and album name appear in Overview; cover appears beside the camera while playing, even with a focus timer on the other side.
- [ ] Rapidly skip tracks and change players; old artwork never replaces the current cover. Pause/resume preserves the cover in Overview, stopped playback clears it, and disabled music clears all cover state.
- [ ] Test missing Music artwork, Spotify local files, offline artwork downloads, and Reload album artwork. A placeholder must not block playback controls or timer display.
- [ ] Drop files onto both panel states; drag files out into Finder and another app.
- [ ] Files Tray target adds references once. AirDrop target opens only the native recipient picker and does not add references; test multiple files, folders, cancellation, unavailable receiver, and successful transfer to a second device.
- [ ] AirDrop from a card context menu and the menu bar; cancel a file picker, complete/cancel sharing, then share again.
- [ ] Mirror: allow/deny camera access, no camera, camera in use, horizontal flip, off/retry, and opening from the menu bar.
- [ ] Leave Mirror, close the panel, sleep/wake, switch sessions, and quit: camera turns off. Grant permission after closing the tab: camera must remain off. Reopen rapidly and verify only the visible mirror captures.
- [ ] VoiceOver identifies Files Tray, AirDrop, album artwork, and Mirror controls. Check layouts on notched and non-notched screens.
- [ ] Add duplicates, 25 files, cloud-only files, and externally removed files.
- [ ] Removing one item or clearing the shelf leaves all original files untouched.
- [ ] Relaunch restores the shelf; rename a file and check bookmark recovery.
- [ ] Search, clear a no-match search, sort both ways, and type with the pointer outside the panel. Preview images/PDFs/text/folders, close/reopen Quick Look, and copy a file/path.
- [ ] Remove unavailable references and use card remove buttons; confirm source files remain untouched.
- [ ] Pause/resume/reset a timer; sleep past completion; relaunch during a session.
- [ ] Completion appears once and respects the sound preference.
- [ ] All three timer modes use their custom duration; active timers ignore duration changes. Breaks/reset do not increase today's totals, and a session expiring overnight counts on its deadline day.
- [ ] Upgrade with a running/paused version 0.1 timer; relaunch preserves state and never replays old completion sounds.
- [ ] Battery percentage and charging update after connecting power.
- [ ] From Applications, enable/disable launch at login and verify macOS Login Items.
- [ ] Test the packaged app on both Apple silicon and Intel before claiming hardware validation.

## Limits

- First implementation, not complete NotchNook feature parity.
- No private system-wide Now Playing, arbitrary website inspection, clipboard history, weather, camera recording, or widget plugins. Browser detection is limited to YouTube/YouTube Music in Chrome and Safari.
- One display hosts the panel; it does not follow the pointer across monitors.
- Compact activity shows the playing album cover on the left and a timer or music indicator on the right. It does not show track text. Paused timers remain visible; paused music alone does not keep the notch active.
- Artwork depends on what the selected desktop player exposes. Unavailable covers get a placeholder and retry; there is no title-based album search or unsupported-player fallback.
- AirDrop needs compatible nearby devices and macOS sharing support. Compilation cannot verify actual discovery or transfer. Camera permission and physical hardware likewise require interactive testing.
- The camera cutout has no display pixels; idle behavior is a transparent activation region, with content beside or below the camera when needed.
- Focus history retains the latest 200 completions. Completion feedback requires the app to be running; no scheduled system notifications are implemented.
- The panel may cover menu-bar space and does not reserve system layout space.
- Very narrow layouts can compress content despite constrained window bounds.
- Evaluate Automation and login items from the installed app with stable signing.
- Default signing is ad-hoc; notarization and a release installer are separate steps.
