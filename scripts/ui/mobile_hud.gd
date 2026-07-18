extends CanvasLayer
class_name MobileHUD

const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
const LookPadScript = preload("res://scripts/ui/look_pad.gd")
const CrosshairScript = preload("res://scripts/ui/crosshair.gd")

var player
var move_vector = Vector2.ZERO
var look_delta = Vector2.ZERO
var fire_held = false
var reload_request = false
var knife_request = false
var auto_request = false
var slot_request = -1
var crosshair_enemy = false
var damage_flash = 0.0
var center_message_time = 0.0

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
		damage_overlay.color.a = clamp(damage_flash * 0.45, 0.0, 0.18)
	else:
		damage_overlay.color.a = 0.0
	knife_overlay.modulate.a = move_toward(knife_overlay.modulate.a, 0.0, delta * 5.0)
	crosshair.queue_redraw()

func _build_hud():
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(damage_overlay)
	var top = PanelContainer.new()
	top.position = Vector2(18, 14)
	top.size = Vector2(600, 72)
	top.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(top)
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 24)
	top_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	top.add_child(top_row)
	health_label = _label("HP 100", 25, Color("8cff98"))
	top_row.add_child(health_label)
	score_label = _label("СИНИЕ 0 : 0 КРАСНЫЕ", 23)
	top_row.add_child(score_label)
	timer_label = _label("03:00", 24, Color("ffca3a"))
	top_row.add_child(timer_label)
	coins_label = _label("+0 ◈", 22, Color("ffca3a"))
	coins_label.position = Vector2(1040, 24)
	coins_label.size = Vector2(200, 45)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(coins_label)
	weapon_label = _label("AR-4", 20, Color("9db4c7"))
	weapon_label.position = Vector2(860, 535)
	weapon_label.size = Vector2(300, 35)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(weapon_label)
	ammo_label = _label("30 / 120", 36)
	ammo_label.position = Vector2(940, 570)
	ammo_label.size = Vector2(220, 55)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(ammo_label)
	_build_controls(root)
	crosshair = CrosshairScript.new()
	crosshair.hud = self
	crosshair.position = Vector2(615, 335)
	crosshair.size = Vector2(50, 50)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	center_message = _label("", 32, Color("23e6ff"))
	center_message.position = Vector2(390, 155)
	center_message.size = Vector2(500, 60)
	center_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_message.visible = false
	root.add_child(center_message)
	knife_overlay = _label("УДАР!", 35, Color("ffca3a"))
	knife_overlay.position = Vector2(490, 430)
	knife_overlay.size = Vector2(300, 60)
	knife_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	knife_overlay.modulate.a = 0.0
	root.add_child(knife_overlay)

func _build_controls(root):
	joystick = VirtualJoystickScript.new()
	joystick.position = Vector2(20, 390)
	joystick.size = Vector2(290, 300)
	joystick.vector_changed.connect(func(value): move_vector = value)
	root.add_child(joystick)
	var look_pad = LookPadScript.new()
	look_pad.position = Vector2(360, 100)
	look_pad.size = Vector2(920, 620)
	look_pad.looked.connect(func(value): look_delta += value)
	root.add_child(look_pad)
	var fire = _button("ОГОНЬ", Vector2(1100, 505), Vector2(145, 145), Color("ef476f"))
	fire.button_down.connect(func(): fire_held = true)
	fire.button_up.connect(func(): fire_held = false)
	root.add_child(fire)
	var knife = _button("НОЖ", Vector2(930, 595), Vector2(120, 85), Color("ffca3a"))
	knife.pressed.connect(func(): knife_request = true)
	root.add_child(knife)
	var reload = _button("R", Vector2(1060, 405), Vector2(85, 72), Color("23e6ff"))
	reload.pressed.connect(func(): reload_request = true)
	root.add_child(reload)
	auto_button = _button("", Vector2(1130, 105), Vector2(125, 62), Color("8cff98"))
	auto_button.pressed.connect(func(): auto_request = true)
	root.add_child(auto_button)
	update_auto_button()
	var slots = HBoxContainer.new()
	slots.position = Vector2(385, 632)
	slots.add_theme_constant_override("separation", 8)
	root.add_child(slots)
	for i in range(4):
		var b = _button(str(i + 1), Vector2.ZERO, Vector2(82, 64), Color("23e6ff"))
		b.pressed.connect(_request_slot.bind(i))
		slots.add_child(b)

func _label(text, size, color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _button(text, pos, button_size, accent):
	var button = Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 21)
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.1, 0.16, 0.83)
	normal.border_color = accent
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(22)
	var pressed = normal.duplicate()
	pressed.bg_color = Color(accent, 0.42)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover", normal)
	return button

func _panel_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.1, 0.8)
	style.border_color = Color("23445d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style

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
		auto_button.text = "AUTO\n%s" % ("ON" if SaveData.auto_fire else "OFF")

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
