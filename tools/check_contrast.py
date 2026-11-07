#!/usr/bin/env python3
"""WCAG 2.x contrast check for templates/palettes.json.

Usage: python3 tools/check_contrast.py [path/to/palettes.json]
Checks every text-on-surface pair the UI kit uses. Exit code 1 if any pair is under its target.
Targets: 4.5:1 for body text, 3:1 for large bold labels (buttons, titles) per WCAG 2.x.
"""
import json
import sys
from pathlib import Path

PAIRS = [
    # (foreground key, background key, target, use)
    ("text", "bg0", 4.5, "body text on page background"),
    ("text", "bg1", 4.5, "body text on panel"),
    ("text", "bg2", 4.5, "body text on raised card"),
    ("textMuted", "bg0", 4.5, "secondary text on page background"),
    ("textMuted", "bg1", 4.5, "secondary text on panel"),
    ("onPrimary", "primary", 4.5, "primary button label"),
    ("onSecondary", "secondary", 4.5, "secondary button label"),
    ("onAccent", "accent", 4.5, "accent button label"),
    ("onSuccess", "success", 3.0, "success badge label (large bold)"),
    ("onDanger", "danger", 3.0, "danger badge label (large bold)"),
]


def luminance(hex_color: str) -> float:
    hex_color = hex_color.lstrip("#")
    channels = [int(hex_color[i : i + 2], 16) / 255 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def main() -> int:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent.parent / "templates" / "palettes.json"
    palettes = json.loads(path.read_text())
    failures = 0
    for name, colors in palettes.items():
        print(f"\n{name}")
        for fg, bg, target, use in PAIRS:
            ratio = contrast(colors[fg], colors[bg])
            ok = ratio >= target
            failures += 0 if ok else 1
            print(f"  {'PASS' if ok else 'FAIL'}  {ratio:5.2f}:1 (need {target}) {fg} on {bg}  {use}")
    print(f"\n{failures} failing pair(s)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
