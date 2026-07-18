#!/usr/bin/env python3
"""Fast repository checks before Godot performs the authoritative import/export."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
required = [
    "project.godot",
    "export_presets.cfg",
    ".github/workflows/android.yml",
    "scenes/main.tscn",
    "autoload/save_data.gd",
    "scripts/main.gd",
    "scripts/game/arena.gd",
    "scripts/game/player.gd",
    "scripts/game/bot.gd",
    "scripts/game/combatant.gd",
    "scripts/ui/menu_screen.gd",
    "scripts/ui/mobile_hud.gd",
    "scripts/ui/virtual_joystick.gd",
    "scripts/ui/look_pad.gd",
    "scripts/ui/crosshair.gd",
]
errors: list[str] = []

for item in required:
    if not (root / item).is_file():
        errors.append(f"Missing required file: {item}")

resource_pattern = re.compile(r'(?:preload|load)\("res://([^"\n]+)"\)')
scene_resource_pattern = re.compile(r'path="res://([^"\n]+)"')
class_pattern = re.compile(r'^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$', re.MULTILINE)
classes: dict[str, Path] = {}


def balanced_delimiters(text: str, relative: Path) -> None:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    quote = ""
    escaped = False
    for line_no, raw_line in enumerate(text.splitlines(), 1):
        line = raw_line
        i = 0
        while i < len(line):
            char = line[i]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = ""
                i += 1
                continue
            if char in ('"', "'"):
                quote = char
            elif char == "#":
                break
            elif char in "([{":
                stack.append((char, line_no))
            elif char in ")]}":
                if not stack or stack[-1][0] != pairs[char]:
                    errors.append(f"Unbalanced '{char}' in {relative}:{line_no}")
                    return
                stack.pop()
            i += 1
    if quote:
        errors.append(f"Unclosed string in {relative}")
    if stack:
        char, line_no = stack[-1]
        errors.append(f"Unclosed '{char}' in {relative}:{line_no}")


for path in sorted(root.rglob("*.gd")):
    text = path.read_text(encoding="utf-8")
    relative = path.relative_to(root)
    balanced_delimiters(text, relative)
    for rel in resource_pattern.findall(text):
        if not (root / rel).exists():
            errors.append(f"Broken resource reference: {relative} -> res://{rel}")
    for name in class_pattern.findall(text):
        if name in classes:
            errors.append(f"Duplicate class_name {name}: {classes[name]} and {relative}")
        classes[name] = relative

for scene in root.rglob("*.tscn"):
    text = scene.read_text(encoding="utf-8")
    for rel in scene_resource_pattern.findall(text):
        if not (root / rel).exists():
            errors.append(f"Broken scene resource: {scene.relative_to(root)} -> res://{rel}")

project_text = (root / "project.godot").read_text(encoding="utf-8") if (root / "project.godot").is_file() else ""
main_scene_match = re.search(r'run/main_scene="res://([^"\n]+)"', project_text)
if not main_scene_match:
    errors.append("project.godot has no run/main_scene")
elif not (root / main_scene_match.group(1)).is_file():
    errors.append(f"Main scene does not exist: res://{main_scene_match.group(1)}")

preset_text = (root / "export_presets.cfg").read_text(encoding="utf-8") if (root / "export_presets.cfg").is_file() else ""
for required_setting in [
    'name="Android"',
    'export_path="build/BoomArena-debug.apk"',
    'architectures/arm64-v8a=true',
    'package/unique_name="com.franbpm.boomarena"',
]:
    if required_setting not in preset_text:
        errors.append(f"Android export preset is missing: {required_setting}")

if errors:
    print("Validation failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print(f"Validation passed: {len(list(root.rglob('*.gd')))} GDScript files, {len(classes)} named classes, all resource links present.")
