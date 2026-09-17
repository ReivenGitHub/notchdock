# Validation record

## Verified macOS build — 2026-09-17

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

The project contains 42 source, configuration, test, build, and documentation files. Compiling both architectures does not replace interactive testing on both types of Mac, older supported macOS versions, and notched and non-notched displays.
