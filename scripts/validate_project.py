#!/usr/bin/env python3
"""Repository checks before Godot performs the authoritative import/export."""
from pathlib import Path
import re
import sys
import wave

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
    "scripts/ui/scope_overlay.gd",
    "scripts/ui/store_item_icon.gd",
    "scripts/ui/control_layout_editor.gd",
    "signing/boomarena-debug.keystore",
    "gdlintrc",
]
audio_files = [
    "footstep1.wav", "footstep2.wav", "grenade.wav", "knife.wav",
    "machinegun.wav", "pistol.wav", "reload.wav", "rifle.wav",
    "rifle_fast.wav", "rifle_heavy.wav", "rifle_elite.wav",
    "shotgun.wav", "sniper.wav",
]
required += [f"assets/audio/{name}" for name in audio_files]
errors: list[str] = []

for item in required:
    if not (root / item).is_file():
        errors.append(f"Missing required file: {item}")

for name in audio_files:
    path = root / "assets" / "audio" / name
    if not path.is_file():
        continue
    try:
        with wave.open(str(path), "rb") as wav:
            if wav.getnchannels() != 1 or wav.getsampwidth() != 2:
                errors.append(f"Audio must be 16-bit mono WAV: {path.relative_to(root)}")
            if wav.getnframes() <= 100:
                errors.append(f"Audio file is suspiciously short: {path.relative_to(root)}")
    except wave.Error as exc:
        errors.append(f"Invalid WAV {path.relative_to(root)}: {exc}")

resource_pattern = re.compile(r'(?:preload|load)\("res://([^"\n]+)"\)')
scene_resource_pattern = re.compile(r'path="res://([^"\n]+)"')
class_pattern = re.compile(r'^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$', re.MULTILINE)
extends_pattern = re.compile(r'^extends\s+([A-Za-z_][A-Za-z0-9_]*)\s*$', re.MULTILINE)
func_pattern = re.compile(r'^func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', re.MULTILINE)
classes: dict[str, Path] = {}
class_extends: list[tuple[str, Path]] = []
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
            elif char in ")]}" and (not stack or stack[-1][0] != pairs[char]):
                errors.append(f"Unbalanced '{char}' in {relative}:{line_no}")
                return
            elif char in ")]}":
                stack.pop()
            i += 1
    if quote:
        errors.append(f"Unclosed string in {relative}")
    if stack:
        char, line_no = stack[-1]
        errors.append(f"Unclosed '{char}' in {relative}:{line_no}")


def reject_empty_function_bodies(text: str, relative: Path) -> None:
    lines = text.splitlines()
    function_header = re.compile(r"^func\s+[A-Za-z_][A-Za-z0-9_]*\s*\(.*\)\s*(?:->\s*[^:]+)?\s*:\s*$")
    for index, line in enumerate(lines):
        if not function_header.match(line):
            continue
        cursor = index + 1
        while cursor < len(lines) and (not lines[cursor].strip() or lines[cursor].lstrip().startswith("#")):
            cursor += 1
        if cursor >= len(lines) or not lines[cursor].startswith(("\t", "    ")):
            errors.append(f"Empty function body without pass/code: {relative}:{index + 1}")



for path in sorted(root.rglob("*.gd")):
    text = path.read_text(encoding="utf-8")
    relative = path.relative_to(root)
    balanced_delimiters(text, relative)
    reject_empty_function_bodies(text, relative)
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

for required_setting in [
    "textures/vram_compression/import_etc2_astc=true",
    "window/handheld/orientation=4",
    'window/stretch/aspect="expand"',
]:
    if required_setting not in project_text:
        errors.append(f"project.godot is missing: {required_setting}")

preset_path = root / "export_presets.cfg"
preset_text = preset_path.read_text(encoding="utf-8") if preset_path.is_file() else ""
for required_setting in [
    'name="Android"',
    'export_path="build/BoomArena-debug.apk"',
    'architectures/arm64-v8a=true',
    'package/unique_name="com.franbpm.boomarena"',
    'version/code=11',
    'version/name="0.9.0"',
]:
    if required_setting not in preset_text:
        errors.append(f"Android export preset is missing: {required_setting}")

checks = {
    "autoload/save_data.gd": [
        "MAX_PLAYER_LEVEL = 5", "LEVEL_XP = [0, 250, 700, 1400, 2400]",
        '"rifle_vortex"', '"rifle_bastion"', '"rifle_phoenix"',
        '"reload_time": 2.0', '"reload_time": 5.0', '"reload_time": 4.0',
        '"reload_time": 3.0', "HELMET_UNLOCK_LEVEL = 3",
        "FLASH_GRENADE_UNLOCK_LEVEL = 3", "REPAIR_KIT_PRICE = 2000",
        "REPAIR_KIT_RESTORE = 100", "DEFAULT_CONTROL_LAYOUT", "training_weapon",
    ],
    "scripts/game/arena.gd": [
        'score_limit = 0 if mode_id == "training" else 1000 if mode_id == "saloon" else 25',
        "func _update_control_zone", "zone_score_accumulator", "_add_team_score(active_team, 5)",
        "FIRST BLOOD", "DOUBLE KILL", "TRIPLE KILL", "UNSTOPPABLE",
        "func _build_saloon", "func _build_training_ground", "func get_bot_objective",
        "func throw_flash_grenade", "show_match_results", "signal arena_ready",
    ],
    "scripts/game/bot.gd": [
        "bot_mag", "reload_finish_time", "func _start_reload", "func _finish_reload",
        "func _update_footsteps", "get_bot_objective", "training_dummy", "func apply_flash",
    ],
    "scripts/game/player.gd": [
        "func _handle_weapon_selection", "consume_slot_request", "Input.is_action_just_pressed",
        "func _update_footsteps", "func _play_weapon_sound", "func throw_flash_grenade",
        "func use_repair_kit", "func set_training_weapon", "headshot_damage_multiplier",
    ],
    "scripts/main.gd": [
        "ResourceLoader.load", "func _watch_arena_startup", "BOOM_ARENA_SMOKE_TEST_OK",
        "BOOM_ARENA_TRAINING_SMOKE_TEST_OK", "--smoke-training",
    ],
    "scripts/ui/menu_screen.gd": [
        "МАГАЗИН", "ПОЛИГОН", "РАСПОЛОЖЕНИЕ КНОПОК УПРАВЛЕНИЯ",
        "ControlLayoutEditorScript", "ТАКТИЧЕСКАЯ КАСКА", "StoreIconScript",
    ],
    "scripts/ui/mobile_hud.gd": [
        "func set_precombat_mode", "func update_zone", "ScopeOverlayScript",
        "func _apply_saved_control_layout", "func apply_flash", "flash_overlay",
    ],
    "scripts/ui/control_layout_editor.gd": [
        "class_name ControlLayoutEditor", "SaveData.set_control_layout",
        "SaveData.reset_control_layout", "func _move_proxy",
    ],
}

arena_path = root / "scripts/game/arena.gd"
if arena_path.is_file():
    arena_source = arena_path.read_text(encoding="utf-8")
    if arena_source.count("\t_create_control_point()") != 1:
        errors.append("Saloon must create exactly one central control point")

combatant_path = root / "scripts/game/combatant.gd"
if combatant_path.is_file():
    combatant_text = combatant_path.read_text(encoding="utf-8")
    methods = set(func_pattern.findall(combatant_text))
    for hook in ("on_health_changed", "on_respawned"):
        if hook not in methods:
            errors.append(f"Combatant base class must define hook method: {hook}")


workflow_text = (root / ".github/workflows/android.yml").read_text(encoding="utf-8")
if "--headless --path . --import" not in workflow_text:
    errors.append("GitHub Actions must import Godot resources before the battle smoke test")
if workflow_text.find("--headless --path . --import") > workflow_text.find("-- --smoke-test"):
    errors.append("Godot resource import must run before the battle smoke test")
if "-- --smoke-training" not in workflow_text:
    errors.append("GitHub Actions must run the training ground smoke test")
if "BOOM_ARENA_TRAINING_SMOKE_TEST_OK" not in workflow_text:
    errors.append("Training smoke test marker is missing from GitHub Actions")

raw_audio_preloads = []
for gd_file in sorted(root.rglob("*.gd")):
    source = gd_file.read_text(encoding="utf-8")
    if 'preload("res://assets/audio/' in source:
        raw_audio_preloads.append(str(gd_file))
if raw_audio_preloads:
    errors.append("Raw audio must be loaded after import, not preloaded during script parsing: " + ", ".join(raw_audio_preloads))

if errors:
    print("Validation failed:")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print(
    f"Validation passed: {len(list(root.rglob('*.gd')))} GDScript files, "
    f"{len(classes)} named classes, audio and Android export settings checked."
)
