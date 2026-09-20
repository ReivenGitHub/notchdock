# Validation record

## Version 0.3 — verified macOS build, 2026-09-17

[Final v0.3 build](https://github.com/ReivenGitHub/notchdock/actions/runs/35225569221) succeeded for source commit `9bb2acae53c35abe60bb469ecb61ae68d2f538c0`. Results were checked from the completed job and logs on September 20.

| Check | Observed result |
| --- | --- |
| Native compilation on macOS 15, Apple Swift 6.1.2 | Passed; no Swift compiler warnings or errors. |
| XCTest cases | All 49 executed and passed, including Music metadata/artwork script compilation without execution. |
| Apple silicon and Intel release builds | Both passed. |
| Universal executable | Passed architecture verification for arm64 and x86_64. |
| Permission metadata, signature structure, property list, packaging | Passed. Signature is ad-hoc, not notarized. |
| Live player artwork, AirDrop transfers, camera and physical notch | Not interactively tested; see the [manual checklist](TESTING.md). |

The final source fixes the artwork concurrency warning by returning immutable thumbnail data to the UI actor. Queued scripts also check whether the player is still running before querying it.

### Download version 0.3

[Download NotchDock 0.3 for Apple silicon and Intel](https://github.com/ReivenGitHub/notchdock/actions/runs/35225569221/artifacts/10498529932)

Unzip the artifact and its included `NotchDock-macOS.zip`. Quit the older app, then replace NotchDock in Applications. Existing shelf references and timer state are preserved. The artifact includes `SHA256SUMS.txt` and expires **2026-10-01**.

Files now has separate Files Tray and AirDrop targets. Mirror requests camera access when opened and stops capture when closed or hidden. Enable the selected desktop music player to see artwork beside the notch and in Overview; artwork availability depends on the player and track. The existing first-launch approval instructions still apply.

## Version 0.2 — verified macOS build, 2026-09-17

[Build run #5](https://github.com/ReivenGitHub/notchdock/actions/runs/35181914960) completed successfully for source commit `759edcf0a6a4e24052d8bbc26a6f35c22b4ca300`, including the transparent-notch pointer handling. The runner used macOS 15 and Apple Swift 6.1.2. These results were read from the completed job and its logs.

| Check | Observed result |
| --- | --- |
| Static packaging, shell syntax, metadata, and documentation links | Passed locally and on the Mac runner. |
| Native Swift app compilation | Passed. No Swift compiler warnings or errors in the job log. |
| XCTest regression cases | All 34 executed; the test step passed. |
| Apple silicon and Intel release builds | Passed for both architectures. |
| Universal executable | Passed `lipo` verification for `arm64` and `x86_64`. |
| Bundle signature and property list | Passed strict ad-hoc signature verification and property-list validation. |
| App archive and checksum | Created and uploaded successfully. |
| Physical-notch hover/drop, previews, shortcuts, and external displays | Not interactively tested; use the [manual checklist](TESTING.md). |
| Apple notarization | Not performed; the first-launch approval instructions still apply. |

### Download version 0.2

[NotchDock 0.2 universal Mac build](https://github.com/ReivenGitHub/notchdock/actions/runs/35181914960/artifacts/10480902953)

The artifact contains `NotchDock-macOS.zip` and `SHA256SUMS.txt`. Unzip both layers, quit the older NotchDock, and replace the app in Applications. Existing shelf references and valid timer state are restored. Unpin and close the panel, with no timer or playing music, to see the quiet idle notch. Hover near the camera's lower edge to open it.

GitHub reports an expiry of **2026-10-01**. Later successful runs provide fresh artifacts. The prior feature run (#4) also passed; run #5 includes the final pointer activation change.

## Version 0.1 — verified macOS build, 2026-09-17

[Build run #3](https://github.com/ReivenGitHub/notchdock/actions/runs/35178759069) completed successfully for source commit `d7162f6b45204e71e8d1607eb4b71802ed7230ec`.

The runner used macOS 15 and Apple Swift 6.1.2. Results below were read from the completed job and its logs, not inferred from the presence of test files.

| Check | Observed result |
| --- | --- |
| Static packaging, metadata, shell syntax, links, and SVG checks | Passed on the macOS runner. |
| Native Swift executable compilation | Passed. |
| Core XCTest cases | All 18 executed; the test step passed. |
| Release build for Apple silicon | Passed. |
| Release build for Intel | Passed. |
| Universal executable | Passed `lipo` verification for `arm64` and `x86_64`. |
| Bundle signature structure | Passed `codesign --verify --strict`; this is an ad-hoc signature. |
| Application property list | Passed `plutil -lint`. |
| App archive | Created and uploaded successfully. |
| Native interaction and physical hardware QA | Not performed; complete the [manual checklist](TESTING.md). |
| Apple notarization | Not performed; see [distribution instructions](DISTRIBUTION.md). |

### Download

[NotchDock-macOS build artifact](https://github.com/ReivenGitHub/notchdock/actions/runs/35178759069/artifacts/10479269734)

The artifact contains `NotchDock-macOS.zip` and `SHA256SUMS.txt`. Unzip the artifact, then unzip the included app ZIP. The executable permissions and app bundle metadata are preserved by the inner ZIP.

GitHub reports that this artifact expires on **2026-10-01**. Later successful workflow runs provide fresh artifacts. The source and build scripts remain in the repository.

### Fixes made during native verification

1. Added explicit CoreGraphics imports for the macOS geometry overlays in the core module and its geometry tests.
2. Corrected the argument order of the final `lipo -verify_arch` command. The preceding run had already passed compilation, all 18 XCTest cases, signing checks, and app packaging; its final architecture-check command had failed before artifact upload.

## Initial source preparation

The initial Linux authoring environment had no Swift compiler or macOS SDK. Packaging metadata, shell syntax, documentation links, Python syntax, and workflow YAML were checked there. The interface SVG was rendered and inspected as an illustration, not as proof of the native UI.

The initial project contained 42 source, configuration, test, build, and documentation files. Compiling both architectures does not replace interactive testing on both types of Mac, older supported macOS versions, and notched and non-notched displays.
