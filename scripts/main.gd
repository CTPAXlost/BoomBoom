extends Node

const MenuScreen = preload("res://scripts/ui/menu_screen.gd")
const Arena = preload("res://scripts/game/arena.gd")

var current_screen

func _ready():
	SaveData.apply_runtime_settings()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	_ensure_input_actions()
	show_menu()

func _ensure_input_actions():
	var keys = {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"reload": KEY_R,
		"knife": KEY_Q,
		"toggle_auto": KEY_F,
		"slot_1": KEY_1,
		"slot_2": KEY_2,
		"slot_3": KEY_3,
		"slot_4": KEY_4,
		"ui_cancel": KEY_ESCAPE
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var exists = false
		for existing in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == keys[action]:
				exists = true
		if not exists:
			var event = InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
	var has_mouse = false
	for existing in InputMap.action_get_events("fire"):
		if existing is InputEventMouseButton and existing.button_index == MOUSE_BUTTON_LEFT:
			has_mouse = true
	if not has_mouse:
		var mouse = InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mouse)

func clear_screen():
	if is_instance_valid(current_screen):
		current_screen.queue_free()
	current_screen = null

func show_menu(result_text = ""):
	clear_screen()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = MenuScreen.new()
	add_child(current_screen)
	current_screen.start_match.connect(start_match)
	if result_text != "":
		current_screen.call_deferred("show_result", result_text)

func start_match():
	clear_screen()
	current_screen = Arena.new()
	add_child(current_screen)
	current_screen.match_finished.connect(_on_match_finished)

func _on_match_finished(summary):
	show_menu(summary)
