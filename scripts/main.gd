extends Node

const MenuScreen = preload("res://scripts/ui/menu_screen.gd")
const ARENA_SCRIPT_PATH = "res://scripts/game/arena.gd"

var current_screen
var pending_screen
var startup_attempt = 0
var smoke_test_mode = false
var smoke_session_type = "match"

func _ready():
	SaveData.apply_runtime_settings()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	_ensure_input_actions()
	var command_args = OS.get_cmdline_user_args()
	smoke_test_mode = command_args.has("--smoke-test") or command_args.has("--smoke-training")
	smoke_session_type = "training" if command_args.has("--smoke-training") else "match"
	show_menu()
	if smoke_test_mode:
		call_deferred("start_match", smoke_session_type)

func _ensure_input_actions():
	var keys = {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"reload": KEY_R,
		"knife": KEY_Q,
		"medkit": KEY_H,
		"grenade": KEY_G,
		"flash_grenade": KEY_C,
		"repair_kit": KEY_V,
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
	_ensure_mouse_action("fire", MOUSE_BUTTON_LEFT)
	_ensure_mouse_action("aim", MOUSE_BUTTON_RIGHT)

func _ensure_mouse_action(action, button_index):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var exists = false
	for existing in InputMap.action_get_events(action):
		if existing is InputEventMouseButton and existing.button_index == button_index:
			exists = true
	if not exists:
		var mouse = InputEventMouseButton.new()
		mouse.button_index = button_index
		InputMap.action_add_event(action, mouse)

func clear_screen():
	if is_instance_valid(current_screen):
		current_screen.queue_free()
	current_screen = null

func _clear_pending_screen():
	if is_instance_valid(pending_screen):
		pending_screen.queue_free()
	pending_screen = null

func show_menu():
	startup_attempt += 1
	_clear_pending_screen()
	clear_screen()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = MenuScreen.new()
	add_child(current_screen)
	current_screen.start_match.connect(start_match)

func start_match(session_type = "match"):
	if is_instance_valid(pending_screen):
		return
	var arena_script = ResourceLoader.load(ARENA_SCRIPT_PATH)
	if arena_script == null or not (arena_script is Script):
		_show_start_error("Не удалось загрузить боевую сцену.")
		return
	if not arena_script.can_instantiate():
		_show_start_error("Скрипт боевой сцены содержит ошибку и не может быть создан.")
		return
	var arena = arena_script.new()
	if arena == null:
		_show_start_error("Не удалось создать боевую сцену.")
		return
	if arena.has_method("configure_session"):
		arena.configure_session(str(session_type))
	pending_screen = arena
	if not pending_screen.has_signal("arena_ready"):
		_show_start_error("В боевой сцене отсутствует сигнал готовности.")
		_clear_pending_screen()
		return
	pending_screen.connect("arena_ready", Callable(self, "_on_arena_ready"), CONNECT_ONE_SHOT)
	pending_screen.connect("match_finished", Callable(self, "_on_match_finished"))
	if is_instance_valid(current_screen) and current_screen.has_method("show_start_loading"):
		current_screen.show_start_loading()
	startup_attempt += 1
	var attempt = startup_attempt
	_watch_arena_startup(attempt)
	add_child(pending_screen)

func _watch_arena_startup(attempt):
	await get_tree().create_timer(8.0).timeout
	if attempt != startup_attempt or not is_instance_valid(pending_screen):
		return
	_clear_pending_screen()
	_show_start_error("Боевая сцена не запустилась. Сборка остановлена безопасно.")
	if smoke_test_mode:
		get_tree().quit(2)

func _on_arena_ready():
	if not is_instance_valid(pending_screen):
		return
	startup_attempt += 1
	var old_screen = current_screen
	current_screen = pending_screen
	pending_screen = null
	if is_instance_valid(old_screen):
		old_screen.queue_free()
	if smoke_test_mode:
		if smoke_session_type == "training":
			print("BOOM_ARENA_TRAINING_SMOKE_TEST_OK")
		else:
			print("BOOM_ARENA_SMOKE_TEST_OK")
		await get_tree().process_frame
		get_tree().quit(0)

func _show_start_error(message):
	push_error(message)
	if is_instance_valid(current_screen) and current_screen.has_method("show_start_error"):
		current_screen.show_start_error(message)
	if smoke_test_mode:
		get_tree().quit(1)

func _on_match_finished():
	show_menu()
