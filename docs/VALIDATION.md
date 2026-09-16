# Validation record

## Initial source preparation

The initial Linux authoring environment had no Swift compiler or macOS SDK. Packaging metadata, shell syntax, documentation links, Python syntax, and workflow YAML were checked there. The interface SVG was rendered and visually inspected as a design illustration, not as proof of the native UI.

## GitHub publication

The owner created [ReivenGitHub/notchdock](https://github.com/ReivenGitHub/notchdock). The source, 18 test cases, and macOS build workflow are included in this commit. The first native build has not yet been recorded in this document; check [Actions](https://github.com/ReivenGitHub/notchdock/actions/workflows/macos.yml) for live results.

| Check | Status at initial upload |
| --- | --- |
| Static packaging and metadata checks | Run locally before upload. |
| Native Swift compilation | Awaiting macOS workflow. |
| 18 XCTest cases | Awaiting macOS workflow. |
| Universal app packaging | Awaiting macOS workflow. |
| Native interaction and hardware QA | Not performed; requires the [manual checklist](TESTING.md). |
| Apple notarization | Not performed; default builds are ad-hoc signed. |

Update this record with observed results and run links rather than assuming an unrun check passed.
