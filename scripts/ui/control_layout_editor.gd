extends Control
class_name ControlLayoutEditor

signal closed

var preview
var dragging_key = ""
var drag_offset = Vector2.ZERO
var proxies = {}
var status_label

const DISPLAY_NAMES = {
	"joystick": "ДЖОЙСТИК",
	"fire": "ОГОНЬ",
	"aim": "ПРИЦЕЛ",
	"knife": "НОЖ",
	"reload": "R",
	"medkit": "АПТЕЧКА",
	"grenade": "ГРАНАТА",
	"flash": "СВЕТОШУМ",
	"repair": "РЕМКОМПЛЕКТ",
	"auto": "AUTO",
	"slots": "ОРУЖИЕ 1 2 3 4"
}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build():
	var shade = ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.035, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var title = _label("РАСПОЛОЖЕНИЕ КНОПОК", 30, Color("23e6ff"))
	title.position = Vector2(28, 18)
	add_child(title)
	var hint = _label("Перетаскивай элементы пальцем. Красная зона сверху оставлена под счёт и статус.", 17, Color("b8c9d8"))
	hint.position = Vector2(30, 58)
	add_child(hint)

	preview = Control.new()
	preview.position = Vector2(24, 94)
	preview.size = Vector2(1232, 548)
	preview.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(preview)
	var preview_bg = ColorRect.new()
	preview_bg.color = Color("1c4a45")
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(preview_bg)
	var safe = ColorRect.new()
	safe.color = Color(0.7, 0.1, 0.15, 0.22)
	safe.anchor_right = 1.0
	safe.anchor_bottom = 0.19
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(safe)

	for key in SaveData.DEFAULT_CONTROL_LAYOUT.keys():
		_create_proxy(str(key))

	var reset_button = Button.new()
	reset_button.text = "СБРОСИТЬ"
	reset_button.position = Vector2(28, 656)
	reset_button.size = Vector2(180, 48)
	_style_button(reset_button, Color("ffca3a"))
	reset_button.pressed.connect(_reset_layout)
	add_child(reset_button)

	var save_button = Button.new()
	save_button.text = "СОХРАНИТЬ"
	save_button.position = Vector2(890, 656)
	save_button.size = Vector2(180, 48)
	_style_button(save_button, Color("8cff98"))
	save_button.pressed.connect(_save_layout)
	add_child(save_button)

	var close_button = Button.new()
	close_button.text = "НАЗАД"
	close_button.position = Vector2(1080, 656)
	close_button.size = Vector2(176, 48)
	_style_button(close_button, Color("ef476f"))
	close_button.pressed.connect(_close)
	add_child(close_button)

	status_label = _label("", 17, Color("8cff98"))
	status_label.position = Vector2(230, 664)
	status_label.size = Vector2(630, 34)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

func _create_proxy(key):
	var data = SaveData.control_layout.get(key, SaveData.DEFAULT_CONTROL_LAYOUT[key])
	var button = Button.new()
	button.text = DISPLAY_NAMES.get(key, key.to_upper())
	button.position = Vector2(float(data.x) * preview.size.x, float(data.y) * preview.size.y)
	button.size = Vector2(float(data.w) * preview.size.x, float(data.h) * preview.size.y)
	button.custom_minimum_size = Vector2(62, 42)
	button.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_style_button(button, Color("23e6ff") if key != "fire" else Color("ef476f"))
	button.gui_input.connect(_on_proxy_input.bind(key, button))
	preview.add_child(button)
	proxies[key] = button

func _on_proxy_input(event, key, button):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging_key = str(key)
			drag_offset = event.position
		else:
			dragging_key = ""
		button.accept_event()
	elif event is InputEventScreenDrag and dragging_key == str(key):
		_move_proxy(button, button.position + event.relative)
		button.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging_key = str(key)
			drag_offset = event.position
		else:
			dragging_key = ""
		button.accept_event()
	elif event is InputEventMouseMotion and dragging_key == str(key) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_proxy(button, button.position + event.relative)
		button.accept_event()

func _move_proxy(button, target_position):
	var max_position = preview.size - button.size
	button.position = Vector2(
		clamp(target_position.x, 0.0, max_position.x),
		clamp(target_position.y, preview.size.y * 0.19, max_position.y)
	)

func _save_layout():
	var result = {}
	for key in proxies:
		var button = proxies[key]
		result[key] = {
			"x": button.position.x / preview.size.x,
			"y": button.position.y / preview.size.y,
			"w": button.size.x / preview.size.x,
			"h": button.size.y / preview.size.y
		}
	SaveData.set_control_layout(result)
	status_label.text = "Расположение сохранено"

func _reset_layout():
	SaveData.reset_control_layout()
	for key in proxies:
		var data = SaveData.control_layout[key]
		var button = proxies[key]
		button.position = Vector2(float(data.x) * preview.size.x, float(data.y) * preview.size.y)
		button.size = Vector2(float(data.w) * preview.size.x, float(data.h) * preview.size.y)
	status_label.text = "Возвращена стандартная раскладка"

func _close():
	closed.emit()
	queue_free()

func _label(text, font_size, color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _style_button(button, accent):
	button.add_theme_font_size_override("font_size", 17)
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("13283c")
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	var pressed = normal.duplicate()
	pressed.bg_color = Color(accent, 0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
