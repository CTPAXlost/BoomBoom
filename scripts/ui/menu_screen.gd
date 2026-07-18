extends Control

signal start_match

var coins_label
var shop_panel
var result_popup
var active_slot = 0
var slot_buttons = []
var weapon_cards = {}

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_header()
	_build_main_panel()
	_build_shop()
	_build_result_popup()
	refresh()

func _build_background():
	var bg = ColorRect.new()
	bg.color = Color("07111f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow = ColorRect.new()
	glow.color = Color(0.05, 0.22, 0.32, 0.35)
	glow.position = Vector2(0, 0)
	glow.size = Vector2(1280, 170)
	bg.add_child(glow)

func make_label(text, size = 24, color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func style_button(button, accent = Color("23e6ff")):
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("13283c")
	normal.border_color = Color(accent, 0.85)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(14)
	var hover = normal.duplicate()
	hover.bg_color = Color("1a3b55")
	var pressed = normal.duplicate()
	pressed.bg_color = Color(accent, 0.35)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

func panel_style(color = Color("0d1c2b")):
	var box = StyleBoxFlat.new()
	box.bg_color = Color(color, 0.96)
	box.border_color = Color("23445d")
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	return box

func _build_header():
	var title = make_label("BOOM ARENA", 42, Color("23e6ff"))
	title.position = Vector2(48, 28)
	add_child(title)
	var subtitle = make_label("МОБИЛЬНЫЙ FPS • ПРОТОТИП 0.2", 18, Color("9db4c7"))
	subtitle.position = Vector2(51, 83)
	add_child(subtitle)
	coins_label = make_label("", 28, Color("ffca3a"))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.position = Vector2(930, 40)
	coins_label.size = Vector2(300, 50)
	add_child(coins_label)

func _build_main_panel():
	var panel = PanelContainer.new()
	panel.position = Vector2(48, 135)
	panel.size = Vector2(480, 525)
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	panel.add_child(box)
	var headline = make_label("КОМАНДНЫЙ БОЙ 4 × 4", 30)
	box.add_child(headline)
	var desc = make_label("Ты + 3 союзных бота против 4 ботов.\nУбийства приносят монеты. Победа — дополнительную награду.", 19, Color("b8c9d8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(410, 85)
	box.add_child(desc)
	var start = Button.new()
	start.text = "НАЧАТЬ БОЙ"
	start.custom_minimum_size = Vector2(410, 78)
	style_button(start, Color("23e6ff"))
	start.pressed.connect(func(): start_match.emit())
	box.add_child(start)
	var shop = Button.new()
	shop.text = "АРСЕНАЛ И СНАРЯЖЕНИЕ"
	shop.custom_minimum_size = Vector2(410, 65)
	style_button(shop, Color("ffca3a"))
	shop.pressed.connect(func(): shop_panel.visible = not shop_panel.visible)
	box.add_child(shop)
	var auto = CheckButton.new()
	auto.text = "Автострельба по цели"
	auto.button_pressed = SaveData.auto_fire
	auto.add_theme_font_size_override("font_size", 21)
	auto.toggled.connect(func(value):
		SaveData.auto_fire = value
		SaveData.save_game()
	)
	box.add_child(auto)
	var controls = make_label("ПК: WASD • мышь • ЛКМ • R • Q • 1–4 • F\nAndroid: левый стик • свайп справа • экранные кнопки", 17, Color("7893a8"))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(controls)

func _build_shop():
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(555, 135)
	shop_panel.size = Vector2(675, 525)
	shop_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(shop_panel)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 13)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	shop_panel.add_child(root)
	root.add_child(make_label("СНАРЯЖЕНИЕ", 29, Color("ffca3a")))
	var slots_title = make_label("Выбери слот, затем оружие:", 18, Color("9db4c7"))
	root.add_child(slots_title)
	var slots = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	root.add_child(slots)
	for i in range(4):
		var b = Button.new()
		b.custom_minimum_size = Vector2(145, 55)
		style_button(b)
		b.pressed.connect(_select_slot.bind(i))
		slots.add_child(b)
		slot_buttons.append(b)
	var clear_button = Button.new()
	clear_button.text = "ОЧИСТИТЬ ВЫБРАННЫЙ СЛОТ"
	clear_button.custom_minimum_size = Vector2(620, 44)
	style_button(clear_button, Color("ef476f"))
	clear_button.pressed.connect(func():
		SaveData.equip_weapon("", active_slot)
		refresh()
	)
	root.add_child(clear_button)
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	root.add_child(cards)
	for id in ["rifle", "shotgun"]:
		var card = _create_weapon_card(id)
		cards.add_child(card)
		weapon_cards[id] = card
	var note = make_label("Пистолет включается автоматически, когда у основного оружия полностью закончились патроны. Нож всегда доступен отдельной кнопкой.", 16, Color("7893a8"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(620, 55)
	root.add_child(note)

func _create_weapon_card(id):
	var catalog = SaveData.weapon_catalog()[id]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(302, 240)
	card.add_theme_stylebox_override("panel", panel_style(Color("102436")))
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	card.add_child(box)
	var name_label = make_label(catalog.name, 23, catalog.color)
	name_label.name = "Name"
	box.add_child(name_label)
	var info = make_label("", 17, Color("b8c9d8"))
	info.name = "Info"
	info.custom_minimum_size = Vector2(270, 70)
	box.add_child(info)
	var action = Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(270, 45)
	style_button(action, catalog.color)
	action.pressed.connect(_weapon_action.bind(id))
	box.add_child(action)
	var upgrade = Button.new()
	upgrade.name = "Upgrade"
	upgrade.custom_minimum_size = Vector2(270, 40)
	style_button(upgrade, Color("8cff98"))
	upgrade.pressed.connect(func():
		SaveData.upgrade_weapon(id)
		refresh()
	)
	box.add_child(upgrade)
	return card

func _select_slot(index):
	active_slot = index
	refresh()

func _weapon_action(id):
	if not SaveData.owned_weapons.get(id, false):
		SaveData.buy_weapon(id)
	else:
		SaveData.equip_weapon(id, active_slot)
	refresh()

func refresh():
	if not is_instance_valid(coins_label):
		return
	coins_label.text = "МОНЕТЫ  ◈  %d" % SaveData.coins
	for i in range(slot_buttons.size()):
		var id = SaveData.loadout[i]
		var weapon_name = "ПУСТО"
		if id != "":
			weapon_name = SaveData.weapon_catalog()[id].type
		slot_buttons[i].text = "%sСЛОТ %d\n%s" % ["> " if active_slot == i else "", i + 1, weapon_name]
	for id in weapon_cards:
		var card = weapon_cards[id]
		var catalog = SaveData.weapon_catalog()[id]
		var level = int(SaveData.weapon_levels.get(id, 1))
		var owned = bool(SaveData.owned_weapons.get(id, false))
		var info = card.get_node("VBoxContainer/Info")
		info.text = "%s • уровень %d\nУрон %.0f • магазин %d" % [catalog.type, level, SaveData.get_weapon_stats(id).damage, catalog.magazine]
		var action = card.get_node("VBoxContainer/Action")
		if owned:
			action.text = "ПОСТАВИТЬ В СЛОТ %d" % (active_slot + 1)
		else:
			action.text = "КУПИТЬ ЗА %d" % catalog.price
		var upgrade = card.get_node("VBoxContainer/Upgrade")
		if not owned:
			upgrade.text = "СНАЧАЛА КУПИТЬ"
			upgrade.disabled = true
		elif level >= 5:
			upgrade.text = "МАКСИМАЛЬНЫЙ УРОВЕНЬ"
			upgrade.disabled = true
		else:
			upgrade.text = "УЛУЧШИТЬ ЗА %d" % SaveData.upgrade_cost(id)
			upgrade.disabled = false

func _build_result_popup():
	result_popup = PanelContainer.new()
	result_popup.visible = false
	result_popup.position = Vector2(345, 205)
	result_popup.size = Vector2(590, 300)
	result_popup.add_theme_stylebox_override("panel", panel_style(Color("102436")))
	add_child(result_popup)
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 30)
	result_popup.add_child(box)
	var label = make_label("", 28, Color("23e6ff"))
	label.name = "Result"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	var close = Button.new()
	close.text = "ПРОДОЛЖИТЬ"
	close.custom_minimum_size = Vector2(400, 60)
	style_button(close)
	close.pressed.connect(func(): result_popup.visible = false)
	box.add_child(close)

func show_result(text):
	result_popup.get_node("VBoxContainer/Result").text = text
	result_popup.visible = true
