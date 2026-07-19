#!/usr/bin/env python3
"""Repository checks before Godot performs the authoritative import/export."""
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
    "assets/icon.png",
    "scripts/main.gd",
    "scripts/game/arena.gd",
    "scripts/game/player.gd",
    "scripts/game/bot.gd",
    "scripts/game/combatant.gd",
    "scripts/ui/menu_screen.gd",
    "scripts/ui/mobile_hud.gd",
    "scripts/ui/virtual_joystick.gd",
    "scripts/ui/look_pad.gd",
    "scripts/ui/touch_action_button.gd",
    "scripts/ui/crosshair.gd",
    "signing/boomarena-debug.keystore",
]
errors: list[str] = []

for item in required:
    if not (root / item).is_file():
        errors.append(f"Missing required file: {item}")

resource_pattern = re.compile(r'(?:preload|load)\("res://([^"\n]+)"\)')
scene_resource_pattern = re.compile(r'path="res://([^"\n]+)"')
class_pattern = re.compile(r'^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$', re.MULTILINE)
extends_pattern = re.compile(r'^extends\s+([A-Za-z_][A-Za-z0-9_]*)\s*$', re.MULTILINE)
func_pattern = re.compile(r'^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', re.MULTILINE)
classes: dict[str, Path] = {}
class_extends: list[tuple[str, Path]] = []

# Native names that must not be reused with class_name in this project/version.
forbidden_class_names = {"VirtualJoystick"}


def balanced_delimiters(text: str, relative: Path) -> None:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    quote = ""
    escaped = False
    for line_no, line in enumerate(text.splitlines(), 1):
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
        if name in forbidden_class_names:
            errors.append(f"class_name {name} conflicts with a native Godot class: {relative}")
        if name in classes:
            errors.append(f"Duplicate class_name {name}: {classes[name]} and {relative}")
        classes[name] = relative
    for base in extends_pattern.findall(text):
        class_extends.append((base, relative))

for base, relative in class_extends:
    if base not in classes and base not in {
        "Node", "Node2D", "Node3D", "Control", "CanvasLayer", "CharacterBody3D"
    }:
        errors.append(f"Unknown script base class {base}: {relative}")

for scene in root.rglob("*.tscn"):
    text = scene.read_text(encoding="utf-8")
    for rel in scene_resource_pattern.findall(text):
        if not (root / rel).exists():
            errors.append(f"Broken scene resource: {scene.relative_to(root)} -> res://{rel}")

project_path = root / "project.godot"
project_text = project_path.read_text(encoding="utf-8") if project_path.is_file() else ""
main_scene_match = re.search(r'run/main_scene="res://([^"\n]+)"', project_text)
if not main_scene_match:
    errors.append("project.godot has no run/main_scene")
elif not (root / main_scene_match.group(1)).is_file():
    errors.append(f"Main scene does not exist: res://{main_scene_match.group(1)}")

if "textures/vram_compression/import_etc2_astc=true" not in project_text:
    errors.append("Android export requires [rendering] textures/vram_compression/import_etc2_astc=true")
if 'window/handheld/orientation=4' not in project_text:
    errors.append("Mobile FPS must use sensor landscape orientation (value 4)")
if 'window/stretch/aspect="expand"' not in project_text:
    errors.append("Mobile UI requires display/window/stretch/aspect=expand")

splash_match = re.search(r'boot_splash/image="res://([^"\n]+)"', project_text)
if splash_match and Path(splash_match.group(1)).suffix.lower() != ".png":
    errors.append("Godot 4.7 boot splash must be a PNG")

preset_path = root / "export_presets.cfg"
preset_text = preset_path.read_text(encoding="utf-8") if preset_path.is_file() else ""
for required_setting in [
    'name="Android"',
    'export_path="build/BoomArena-debug.apk"',
    'architectures/arm64-v8a=true',
    'package/unique_name="com.franbpm.boomarena"',
    'version/code=4',
    'version/name="0.4.0"',
]:
    if required_setting not in preset_text:
        errors.append(f"Android export preset is missing: {required_setting}")

if "gradle_build/use_gradle_build=false" in preset_text:
    for invalid in ("gradle_build/min_sdk=", "gradle_build/target_sdk="):
        if invalid in preset_text:
            errors.append(f"{invalid[:-1]} cannot be overridden while Gradle build is disabled")

combatant_path = root / "scripts/game/combatant.gd"
if combatant_path.is_file():
    combatant_text = combatant_path.read_text(encoding="utf-8")
    methods = set(func_pattern.findall(combatant_text))
    for hook in ("on_health_changed", "on_respawned"):
        if hook not in methods:
            errors.append(f"Combatant base class must define hook method: {hook}")

if errors:
    print("Validation failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print(
    f"Validation passed: {len(list(root.rglob('*.gd')))} GDScript files, "
    f"{len(classes)} named classes, Android export settings checked."
)
