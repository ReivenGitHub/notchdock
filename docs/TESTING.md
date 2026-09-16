# Verification

See [VALIDATION.md](VALIDATION.md) for results actually observed. A checked-in test or workflow is not a passing result. The initial authoring workspace runs Linux without Swift or the macOS SDK.

## Automated checks

`python3 scripts/validate-project.py` checks packaging inputs, shell syntax, property lists, links, and SVG syntax. It does not type-check Swift or run the app.

`swift test --parallel` runs 18 XCTest cases:

- Nine timer cases cover pause/resume, sleep deadlines, one-shot completion, restart, repeated start, reset, JSON restoration, formatting, invalid durations, and backward clock movement.
- Five shelf cases cover duplicates, existing items, URL rejection, capacity, and normalized paths.
- Four geometry cases cover notch clearance, anchoring, negative display coordinates, and narrow-screen containment.

The macOS workflow compiles the executable, runs the tests, builds arm64 and x86_64 binaries, combines them, verifies signature structure, and packages an artifact. A successful build does not confirm interactive integration behavior.

## Manual Mac checklist

Use the bundled `.app`, not a bare command-line executable.

- [ ] Controls remain below a hardware notch; the fallback works on a non-notched display.
- [ ] Hover opens, pointer exit closes, pin prevents automatic closing, and closing restores desktop clicks.
- [ ] ⌥⌘Space, menu bar fallback, and Escape with panel focus work.
- [ ] Settings opens normally; closing it leaves the app running.
- [ ] Spaces, full screen, sleep/wake, and display reconnection preserve placement.
- [ ] Reduce Motion disables window animation.
- [ ] VoiceOver identifies tabs, playback, timer, files, and settings controls.
- [ ] Apple Music: consent, denied consent, retry, playback controls, no track, and player quit.
- [ ] Spotify: repeat the music checks; switch players during a pending poll.
- [ ] Drop files onto both panel states; drag files out into Finder and another app.
- [ ] Add duplicates, 25 files, cloud-only files, and externally removed files.
- [ ] Removing one item or clearing the shelf leaves all original files untouched.
- [ ] Relaunch restores the shelf; rename a file and check bookmark recovery.
- [ ] Pause/resume/reset a timer; sleep past completion; relaunch during a session.
- [ ] Completion appears once and respects the sound preference.
- [ ] Battery percentage and charging update after connecting power.
- [ ] From Applications, enable/disable launch at login and verify macOS Login Items.
- [ ] Test the packaged app on both Apple silicon and Intel before claiming hardware validation.

## Limits

- First implementation, not complete NotchNook feature parity.
- No browser audio, private system-wide Now Playing, album-art downloads, AirDrop target, clipboard history, weather, camera, or widget plugins.
- One display hosts the panel; it does not follow the pointer across monitors.
- Compact status shows the timer or shelf, not continuously polled music metadata.
- The panel may cover menu-bar space and does not reserve system layout space.
- Very narrow layouts can compress content despite constrained window bounds.
- Evaluate Automation and login items from the installed app with stable signing.
- Default signing is ad-hoc; notarization and a release installer are separate steps.
