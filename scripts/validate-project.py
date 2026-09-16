#!/usr/bin/env python3
"""Validate packaging inputs without claiming to compile or run the macOS app."""
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def check(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

required = [
    "Package.swift", "README.md", "LICENSE", "CHANGELOG.md",
    "Resources/Info.plist", "Resources/NotchDock.entitlements",
    "scripts/build-app.sh", "scripts/package-app.sh", "scripts/make-icon.swift",
    ".github/workflows/macos.yml", "docs/ARCHITECTURE.md", "docs/TESTING.md",
    "Sources/NotchDock/App/NotchDockApp.swift",
]
for filename in required:
    check((ROOT / filename).is_file(), f"Missing required file: {filename}")
try:
    with (ROOT / "Resources/Info.plist").open("rb") as file:
        info = plistlib.load(file)
    check(info.get("CFBundleExecutable") == "NotchDock", "App executable name does not match build script")
    check(info.get("CFBundleIdentifier") == "app.notchdock.desktop", "Unexpected bundle identifier")
    check(info.get("LSMinimumSystemVersion") == "13.0", "Deployment target does not match Package.swift")
    check(info.get("LSUIElement") is True, "Menu bar app must use LSUIElement")
    check(bool(info.get("NSAppleEventsUsageDescription")), "Missing Automation purpose string")
    with (ROOT / "Resources/NotchDock.entitlements").open("rb") as file:
        entitlements = plistlib.load(file)
    check(entitlements.get("com.apple.security.automation.apple-events") is True, "Missing Apple Events entitlement")
except (OSError, plistlib.InvalidFileException) as error:
    errors.append(f"Invalid property list: {error}")
for script in [*ROOT.glob("scripts/*.sh"), *ROOT.glob("*.command")]:
    result = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
    check(result.returncode == 0, f"Shell syntax error in {script.name}: {result.stderr}")
sources = sorted((ROOT / "Sources").rglob("*.swift"))
check(sum("@main" in path.read_text() for path in sources) == 1, "Expected one application entry point")
for path in sources:
    text = path.read_text(encoding="utf-8")
    check(not re.search(r"^(<{7}|={7}|>{7})( |$)", text, re.MULTILINE), f"Merge conflict in {path.relative_to(ROOT)}")
    check("REPLACE_ME" not in text, f"Unresolved placeholder in {path.relative_to(ROOT)}")
for path in (ROOT / "docs").glob("*.svg"):
    try:
        ET.parse(path)
    except ET.ParseError as error:
        errors.append(f"Invalid SVG {path.name}: {error}")
for path in [ROOT / "README.md", *ROOT.glob("docs/*.md")]:
    if not path.exists():
        continue
    for target in re.findall(r"\]\(([^)#]+)(?:#[^)]*)?\)", path.read_text()):
        if "://" not in target and not target.startswith(("mailto:", "#")):
            check((path.parent / target).exists(), f"Broken local link in {path.name}: {target}")
if errors:
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    sys.exit(1)
tests = sum(len(re.findall(r"func test\w+\(", path.read_text())) for path in ROOT.glob("Tests/**/*.swift"))
print(f"PASS: packaging metadata, shell syntax, {len(sources)} Swift source files, documentation links, and SVG inputs")
print(f"Found {tests} XCTest cases. This check does not execute them or compile Swift.")
print("On macOS, run: swift test --parallel && bash scripts/package-app.sh universal")
