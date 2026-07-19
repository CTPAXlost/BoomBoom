extends Control

signal start_match

var coins_label
var shop_panel
var settings_panel
var result_popup
var active_slot = 0
var slot_buttons = []
var weapon_cards = {}
var armor_card
var armor_button
var armor_info
var sensitivity_label
var sensitivity_slider
var fps_buttons = {}
var auto_toggle
var loadout_status

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_header()
	_build_main_panel()
	_build_shop()
	_build_settings()
	_build_result_popup()
	_show_shop()
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
	button.add_theme_font_size_override("font_size", 21)
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
	button.add_theme_stylebox_override("focus", pressed)

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
	var subtitle = make_label("МОБИЛЬНЫЙ FPS • ПРОТОТИП 0.5", 18, Color("9db4c7"))
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
	box.add_theme_constant_override("separation", 9)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	panel.add_child(box)
	box.add_child(make_label("КОМАНДНЫЙ БОЙ 4 × 4", 30))
	var desc = make_label("Небольшая карта «Старая ферма».\nТы и 3 союзника против команды из 4 ботов.", 19, Color("b8c9d8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(410, 54)
	box.add_child(desc)
	var start = Button.new()
	start.text = "НАЧАТЬ БОЙ"
	start.custom_minimum_size = Vector2(410, 60)
	style_button(start, Color("23e6ff"))
	start.pressed.connect(func(): start_match.emit())
	box.add_child(start)
	var shop = Button.new()
	shop.text = "АРСЕНАЛ И БРОНЯ"
	shop.custom_minimum_size = Vector2(410, 48)
	style_button(shop, Color("ffca3a"))
	shop.pressed.connect(_show_shop)
	box.add_child(shop)
	var settings = Button.new()
	settings.text = "⚙  НАСТРОЙКИ"
	settings.custom_minimum_size = Vector2(410, 48)
	style_button(settings, Color("b48cff"))
	settings.pressed.connect(_show_settings)
	box.add_child(settings)
	var status_title = make_label("ТЕКУЩЕЕ СНАРЯЖЕНИЕ", 18, Color("9db4c7"))
	box.add_child(status_title)
	loadout_status = make_label("", 18, Color("d8e6f0"))
	loadout_status.name = "LoadoutStatus"
	loadout_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_status.custom_minimum_size = Vector2(410, 54)
	box.add_child(loadout_status)
	var controls = make_label("Слева — движение. Справа — обзор. Отдельные кнопки огня, ножа и перезарядки.", 15, Color("7893a8"))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(controls)

func _build_shop():
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(555, 135)
	shop_panel.size = Vector2(675, 525)
	shop_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(shop_panel)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	shop_panel.add_child(root)
	root.add_child(make_label("АРСЕНАЛ И БРОНЯ", 29, Color("ffca3a")))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	content.add_child(make_label("Выбери слот, затем оружие:", 18, Color("9db4c7")))
	var slots = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	content.add_child(slots)
	for i in range(4):
		var b = Button.new()
		b.custom_minimum_size = Vector2(145, 55)
		style_button(b)
		b.pressed.connect(_select_slot.bind(i))
		slots.add_child(b)
		slot_buttons.append(b)
	var clear_button = Button.new()
	clear_button.text = "ОЧИСТИТЬ ВЫБРАННЫЙ СЛОТ"
	clear_button.custom_minimum_size = Vector2(610, 42)
	style_button(clear_button, Color("ef476f"))
	clear_button.pressed.connect(func():
		SaveData.equip_weapon("", active_slot)
		refresh()
	)
	content.add_child(clear_button)
	var cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	content.add_child(cards)
	for id in ["rifle", "shotgun"]:
		var card = _create_weapon_card(id)
		cards.add_child(card)
		weapon_cards[id] = card
	armor_card = _create_armor_card()
	content.add_child(armor_card)
	var note = make_label("Броня восстанавливается до 100 после каждого возрождения. Сначала урон принимает броня, затем здоровье.", 15, Color("7893a8"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(610, 48)
	content.add_child(note)

func _create_weapon_card(id):
	var catalog = SaveData.weapon_catalog()[id]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(299, 255)
	card.add_theme_stylebox_override("panel", panel_style(Color("102436")))
	var box = VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 13)
	card.add_child(box)
	var name_label = make_label(catalog.name, 22, catalog.color)
	name_label.name = "Name"
	box.add_child(name_label)
	var info = make_label("", 16, Color("b8c9d8"))
	info.name = "Info"
	info.custom_minimum_size = Vector2(270, 103)
	box.add_child(info)
	var action = Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(270, 42)
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

func _create_armor_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 116)
	card.add_theme_stylebox_override("panel", panel_style(Color("102b33")))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	card.add_child(row)
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(make_label("БРОНЯ «ФЕРМЕР»", 22, Color("77d8ff")))
	armor_info = make_label("100 единиц брони поверх HP", 16, Color("b8c9d8"))
	text_box.add_child(armor_info)
	armor_button = Button.new()
	armor_button.custom_minimum_size = Vector2(225, 64)
	style_button(armor_button, Color("77d8ff"))
	armor_button.pressed.connect(func():
		SaveData.buy_armor()
		refresh()
	)
	row.add_child(armor_button)
	return card

func _build_settings():
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(555, 135)
	settings_panel.size = Vector2(675, 525)
	settings_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(settings_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	settings_panel.add_child(box)
	box.add_child(make_label("⚙  НАСТРОЙКИ", 30, Color("b48cff")))
	sensitivity_label = make_label("", 20, Color("d8e6f0"))
	box.add_child(sensitivity_label)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.55
	sensitivity_slider.max_value = 1.8
	sensitivity_slider.step = 0.05
	sensitivity_slider.value = SaveData.look_sensitivity
	sensitivity_slider.custom_minimum_size = Vector2(600, 36)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	box.add_child(sensitivity_slider)
	box.add_child(make_label("ПЛАВНОСТЬ ИГРЫ — ЛИМИТ FPS", 20, Color("d8e6f0")))
	var fps_row = HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 14)
	box.add_child(fps_row)
	var fps_group = ButtonGroup.new()
	for fps in SaveData.ALLOWED_FPS:
		var button = Button.new()
		button.text = "%d FPS" % fps
		button.toggle_mode = true
		button.button_group = fps_group
		button.custom_minimum_size = Vector2(190, 62)
		style_button(button, Color("8cff98") if fps == 60 else Color("23e6ff"))
		button.pressed.connect(_on_fps_selected.bind(fps))
		fps_row.add_child(button)
		fps_buttons[fps] = button
	var fps_note = make_label("30 FPS экономит заряд. 60 FPS — основной режим. 120 FPS требует экрана 120 Гц и сильнее нагревает телефон.", 16, Color("7893a8"))
	fps_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fps_note.custom_minimum_size = Vector2(600, 55)
	box.add_child(fps_note)
	auto_toggle = CheckButton.new()
	auto_toggle.text = "Автострельба при наведении на противника"
	auto_toggle.button_pressed = SaveData.auto_fire
	auto_toggle.add_theme_font_size_override("font_size", 20)
	auto_toggle.toggled.connect(_on_auto_toggled)
	box.add_child(auto_toggle)
	var orientation = make_label("Экран: автоматический поворот только между двумя альбомными положениями.", 16, Color("9db4c7"))
	orientation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(orientation)
	var back = Button.new()
	back.text = "ВЕРНУТЬСЯ В АРСЕНАЛ"
	back.custom_minimum_size = Vector2(600, 54)
	style_button(back, Color("ffca3a"))
	back.pressed.connect(_show_shop)
	box.add_child(back)

func _show_shop():
	if is_instance_valid(shop_panel):
		shop_panel.visible = true
	if is_instance_valid(settings_panel):
		settings_panel.visible = false
	refresh()

func _show_settings():
	if is_instance_valid(shop_panel):
		shop_panel.visible = false
	if is_instance_valid(settings_panel):
		settings_panel.visible = true
	refresh()

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
	var equipped_names = []
	for i in range(slot_buttons.size()):
		var id = SaveData.loadout[i]
		var weapon_name = "ПУСТО"
		if id != "":
			weapon_name = SaveData.weapon_catalog()[id].type
			equipped_names.append(weapon_name)
		slot_buttons[i].text = "%sСЛОТ %d\n%s" % ["> " if active_slot == i else "", i + 1, weapon_name]
	if is_instance_valid(loadout_status):
		var equipment_text = ", ".join(equipped_names) if not equipped_names.is_empty() else "нет основного оружия"
		loadout_status.text = "Оружие: %s\nБроня: %s • FPS: %d" % [equipment_text, "100" if SaveData.armor_owned else "нет", SaveData.target_fps]
	for id in weapon_cards:
		var card = weapon_cards[id]
		var catalog = SaveData.weapon_catalog()[id]
		var stats = SaveData.get_weapon_stats(id)
		var level = int(stats.level)
		var owned = bool(SaveData.owned_weapons.get(id, false))
		var info = card.get_node("Content/Info")
		var head_damage = float(stats.damage) * float(stats.headshot_multiplier)
		info.text = "%s • уровень %d/5\nМощь %d • урон %.0f\nВ голову %.0f (×%.2f) • магазин %d" % [catalog.type, level, int(stats.power), float(stats.damage), head_damage, float(stats.headshot_multiplier), int(catalog.magazine)]
		var action = card.get_node("Content/Action")
		if owned:
			action.text = "ПОСТАВИТЬ В СЛОТ %d" % (active_slot + 1)
		else:
			action.text = "КУПИТЬ ЗА %d" % int(catalog.price)
		var upgrade = card.get_node("Content/Upgrade")
		if not owned:
			upgrade.text = "СНАЧАЛА КУПИТЬ"
			upgrade.disabled = true
		elif level >= 5:
			upgrade.text = "МАКСИМАЛЬНЫЙ УРОВЕНЬ"
			upgrade.disabled = true
		else:
			upgrade.text = "УЛУЧШИТЬ ДО %d ЗА %d" % [level + 1, SaveData.upgrade_cost(id)]
			upgrade.disabled = false
	if is_instance_valid(armor_button):
		if SaveData.armor_owned:
			armor_button.text = "КУПЛЕНО\n+100 БРОНИ"
			armor_button.disabled = true
			armor_info.text = "Куплено. Броня активна в каждом бою."
		else:
			armor_button.text = "КУПИТЬ ЗА %d" % SaveData.ARMOR_PRICE
			armor_button.disabled = false
			armor_info.text = "100 единиц брони поверх HP"
	if is_instance_valid(sensitivity_label):
		sensitivity_label.text = "ЧУВСТВИТЕЛЬНОСТЬ СЕНСОРА: %.2f" % SaveData.look_sensitivity
	if is_instance_valid(sensitivity_slider):
		sensitivity_slider.set_value_no_signal(SaveData.look_sensitivity)
	for fps in fps_buttons:
		fps_buttons[fps].set_pressed_no_signal(int(fps) == SaveData.target_fps)
	if is_instance_valid(auto_toggle):
		auto_toggle.set_pressed_no_signal(SaveData.auto_fire)

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

func _on_sensitivity_changed(value):
	SaveData.look_sensitivity = float(value)
	SaveData.save_game()
	refresh()

func _on_fps_selected(fps):
	SaveData.set_target_fps(int(fps))
	refresh()

func _on_auto_toggled(value):
	SaveData.auto_fire = bool(value)
	SaveData.save_game()
