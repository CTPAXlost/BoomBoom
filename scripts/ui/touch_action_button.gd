extends Control
class_name BoomTouchActionButton

signal pressed
signal held_changed(value)

var text = ""
var accent = Color("23e6ff")
var hold_mode = false
var touch_index = -1
var mouse_down = false
var down = false
var enabled = true
var label
var normal_style
var pressed_style

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_build_visuals()
	set_process_input(true)

func configure(button_text, button_accent, is_hold = false):
	text = str(button_text)
	accent = button_accent
	hold_mode = is_hold
	if is_node_ready():
		_build_visuals()

func _build_visuals():
	if not is_instance_valid(label):
		label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 21)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(label)
	label.text = text
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.035, 0.085, 0.14, 0.82)
	normal_style.border_color = accent
	normal_style.set_border_width_all(3)
	normal_style.set_corner_radius_all(24)
	pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(accent, 0.48)
	queue_redraw()

func set_text(value):
	text = str(value)
	if is_instance_valid(label):
		label.text = text

func set_enabled(value):
	enabled = bool(value)
	modulate.a = 1.0 if enabled else 0.38
	if not enabled:
		force_release()

func _gui_input(event):
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_set_down(true)
			accept_event()
		elif not event.pressed and event.index == touch_index:
			_release_touch(Rect2(Vector2.ZERO, size).has_point(event.position))
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_down = true
			_set_down(true)
		else:
			var inside = Rect2(Vector2.ZERO, size).has_point(event.position)
			mouse_down = false
			_release_mouse(inside)
		accept_event()

func _input(event):
	if not enabled:
		return
	if touch_index >= 0 and event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
		_release_touch(get_global_rect().has_point(event.position))
	elif mouse_down and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		mouse_down = false
		_release_mouse(get_global_rect().has_point(event.position))

func _release_touch(inside):
	touch_index = -1
	var was_down = down
	_set_down(false)
	if was_down and inside:
		pressed.emit()

func _release_mouse(inside):
	var was_down = down
	_set_down(false)
	if was_down and inside:
		pressed.emit()

func _set_down(value):
	if down == value:
		return
	down = value
	if hold_mode:
		held_changed.emit(down)
	queue_redraw()

func force_release():
	touch_index = -1
	mouse_down = false
	_set_down(false)

func _draw():
	var style = pressed_style if down else normal_style
	if style:
		draw_style_box(style, Rect2(Vector2.ZERO, size))
