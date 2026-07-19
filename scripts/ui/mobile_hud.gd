extends CanvasLayer
class_name MobileHUD

const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
const LookPadScript = preload("res://scripts/ui/look_pad.gd")
const CrosshairScript = preload("res://scripts/ui/crosshair.gd")
const TouchButtonScript = preload("res://scripts/ui/touch_action_button.gd")

var player
var move_vector = Vector2.ZERO
var look_delta = Vector2.ZERO
var fire_held = false
var reload_request = false
var knife_request = false
var auto_request = false
var slot_request = -1
var crosshair_enemy = false
var crosshair_kick = 0.0
var shot_flash_time = 0.0
var hit_marker_time = 0.0
var damage_flash = 0.0
var center_message_time = 0.0

var root
var health_label
var ammo_label
var weapon_label
var score_label
var timer_label
var coins_label
var auto_button
var center_message
var joystick
var crosshair
var damage_overlay
var knife_overlay
var look_pad
var fire_button
var knife_button
var reload_button
var slot_buttons = []

func _ready():
	_build_hud()

func set_player(value):
	player = value

func _process(delta):
	if is_instance_valid(player):
		health_label.text = "HP  %d" % int(player.health)
		ammo_label.text = player.ammo_text()
		weapon_label.text = player.weapon_display_name()
	if center_message_time > 0.0:
		center_message_time -= delta
		center_message.modulate.a = clamp(center_message_time * 2.0, 0.0, 1.0)
	else:
		center_message.visible = false
	if damage_flash > 0.0:
		damage_flash -= delta
		damage_overlay.color.a = clamp(damage_flash * 0.5, 0.0, 0.2)
	else:
		damage_overlay.color.a = 0.0
	knife_overlay.modulate.a = move_toward(knife_overlay.modulate.a, 0.0, delta * 5.0)
	shot_flash_time = max(0.0, shot_flash_time - delta)
	hit_marker_time = max(0.0, hit_marker_time - delta)
	crosshair_kick = move_toward(crosshair_kick, 0.0, delta * 7.5)
	crosshair.queue_redraw()

func _build_hud():
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(damage_overlay)

	_build_status(root)
	_build_controls(root)

	crosshair = CrosshairScript.new()
	crosshair.hud = self
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_rect(crosshair, 0.5, 0.5, 0.5, 0.5, -34, -34, 34, 34)
	root.add_child(crosshair)

	center_message = _label("", 32, Color("23e6ff"))
	center_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_message.visible = false
	_anchor_rect(center_message, 0.5, 0.18, 0.5, 0.18, -300, -32, 300, 32)
	root.add_child(center_message)

	knife_overlay = _label("УДАР!", 35, Color("ffca3a"))
	knife_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	knife_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	knife_overlay.modulate.a = 0.0
	_anchor_rect(knife_overlay, 0.5, 0.68, 0.5, 0.68, -150, -35, 150, 35)
	root.add_child(knife_overlay)

func _build_status(parent):
	var health_panel = PanelContainer.new()
	health_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_panel.add_theme_stylebox_override("panel", _panel_style())
	_anchor_rect(health_panel, 0.0, 0.0, 0.0, 0.0, 18, 14, 205, 76)
	parent.add_child(health_panel)
	health_label = _label("HP 100", 25, Color("8cff98"))
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_panel.add_child(health_label)

	var score_panel = PanelContainer.new()
	score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_theme_stylebox_override("panel", _panel_style())
	_anchor_rect(score_panel, 0.5, 0.0, 0.5, 0.0, -250, 14, 250, 86)
	parent.add_child(score_panel)
	var score_box = VBoxContainer.new()
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score_panel.add_child(score_box)
	score_label = _label("СИНИЕ 0 : 0 КРАСНЫЕ", 23)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(score_label)
	timer_label = _label("03:00", 21, Color("ffca3a"))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(timer_label)

	coins_label = _label("+0 ◈", 22, Color("ffca3a"))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_anchor_rect(coins_label, 1.0, 0.0, 1.0, 0.0, -230, 18, -24, 68)
	parent.add_child(coins_label)

	weapon_label = _label("AR-4", 20, Color("9db4c7"))
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_anchor_rect(weapon_label, 1.0, 1.0, 1.0, 1.0, -390, -190, -205, -148)
	parent.add_child(weapon_label)

	ammo_label = _label("30 / 120", 36)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_anchor_rect(ammo_label, 1.0, 1.0, 1.0, 1.0, -390, -154, -205, -94)
	parent.add_child(ammo_label)

func _build_controls(parent):
	look_pad = LookPadScript.new()
	look_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	look_pad.looked.connect(_on_looked)
	parent.add_child(look_pad)

	joystick = VirtualJoystickScript.new()
	_anchor_rect(joystick, 0.0, 0.42, 0.42, 1.0, 10, 0, -8, -8)
	joystick.vector_changed.connect(_on_move_changed)
	parent.add_child(joystick)

	fire_button = _touch_button("ОГОНЬ", Color("ef476f"), true)
	_anchor_rect(fire_button, 1.0, 1.0, 1.0, 1.0, -184, -184, -24, -24)
	fire_button.held_changed.connect(_on_fire_held)
	parent.add_child(fire_button)

	knife_button = _touch_button("НОЖ", Color("ffca3a"))
	_anchor_rect(knife_button, 1.0, 1.0, 1.0, 1.0, -332, -108, -212, -28)
	knife_button.pressed.connect(_request_knife)
	parent.add_child(knife_button)

	reload_button = _touch_button("R", Color("23e6ff"))
	_anchor_rect(reload_button, 1.0, 1.0, 1.0, 1.0, -270, -286, -178, -210)
	reload_button.pressed.connect(_request_reload)
	parent.add_child(reload_button)

	auto_button = _touch_button("", Color("8cff98"))
	_anchor_rect(auto_button, 1.0, 0.0, 1.0, 0.0, -160, 92, -24, 158)
	auto_button.pressed.connect(_request_auto)
	parent.add_child(auto_button)
	update_auto_button()

	var slots = HBoxContainer.new()
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots.add_theme_constant_override("separation", 8)
	_anchor_rect(slots, 0.5, 1.0, 0.5, 1.0, -192, -78, 192, -16)
	parent.add_child(slots)
	for i in range(4):
		var slot_button = _touch_button(str(i + 1), Color("23e6ff"))
		slot_button.custom_minimum_size = Vector2(88, 62)
		slot_button.pressed.connect(_request_slot.bind(i))
		slots.add_child(slot_button)
		slot_buttons.append(slot_button)

	look_pad.set_blocked_controls([fire_button, knife_button, reload_button, auto_button] + slot_buttons)

func _touch_button(text, accent, hold = false):
	var button = TouchButtonScript.new()
	button.configure(text, accent, hold)
	return button

func _label(text, font_size, color = Color.WHITE):
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.1, 0.8)
	style.border_color = Color("23445d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

func _anchor_rect(control, left, top, right, bottom, offset_left, offset_top, offset_right, offset_bottom):
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom

func _on_move_changed(value):
	move_vector = value

func _on_looked(value):
	look_delta += value

func _on_fire_held(value):
	fire_held = value

func _request_reload():
	reload_request = true

func _request_knife():
	knife_request = true

func _request_auto():
	auto_request = true

func consume_look_delta():
	var value = look_delta
	look_delta = Vector2.ZERO
	return value

func consume_reload():
	var value = reload_request
	reload_request = false
	return value

func consume_knife():
	var value = knife_request
	knife_request = false
	return value

func consume_auto_toggle():
	var value = auto_request
	auto_request = false
	return value

func _request_slot(index):
	slot_request = index

func consume_slot_request():
	var value = slot_request
	slot_request = -1
	return value

func update_auto_button():
	if auto_button:
		auto_button.set_text("AUTO\n%s" % ("ON" if SaveData.auto_fire else "OFF"))

func update_match(blue, red, seconds, earned):
	score_label.text = "СИНИЕ %d : %d КРАСНЫЕ" % [blue, red]
	var mins = int(seconds / 60.0)
	var secs = int(seconds) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	coins_label.text = "+%d ◈" % earned

func show_center_message(text):
	center_message.text = text
	center_message.visible = true
	center_message.modulate.a = 1.0
	center_message_time = 1.25

func flash_knife():
	knife_overlay.modulate.a = 1.0

func on_weapon_fired(hit_enemy):
	shot_flash_time = 0.075
	crosshair_kick = min(crosshair_kick + 0.55, 1.0)
	if hit_enemy:
		hit_marker_time = 0.17

func release_controls():
	move_vector = Vector2.ZERO
	look_delta = Vector2.ZERO
	fire_held = false
	if is_instance_valid(joystick):
		joystick.force_release()
	if is_instance_valid(look_pad):
		look_pad.cancel_touch()
	if is_instance_valid(fire_button):
		fire_button.force_release()
