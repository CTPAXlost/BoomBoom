extends Control

signal start_match

const StoreIconScript = preload("res://scripts/ui/store_item_icon.gd")

var coins_label
var profile_label
var nickname_input
var nickname_status
var shop_panel
var settings_panel
var admin_panel
var active_slot = 0
var slot_buttons = []
var weapon_cards = {}
var armor_button
var armor_info
var helmet_button
var helmet_info
var medkit_button
var grenade_button
var consumable_info
var sensitivity_label
var sensitivity_slider
var fps_buttons = {}
var graphics_buttons = {}
var map_buttons = {}
var auto_toggle
var aim_toggle
var fps_counter_toggle
var loadout_status
var map_status
var admin_coins
var admin_status
var start_button
var start_status

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_header()
	_build_main_panel()
	_build_shop()
	_build_settings()
	_build_admin()
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
	button.add_theme_font_size_override("font_size", 19)
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
	var subtitle = make_label("МОБИЛЬНЫЙ FPS • ПРОТОТИП 0.8.2", 18, Color("9db4c7"))
	subtitle.position = Vector2(51, 83)
	add_child(subtitle)
	coins_label = make_label("", 28, Color("ffca3a"))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.position = Vector2(930, 34)
	coins_label.size = Vector2(300, 42)
	add_child(coins_label)
	profile_label = make_label("", 18, Color("8cff98"))
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile_label.position = Vector2(700, 78)
	profile_label.size = Vector2(530, 34)
	add_child(profile_label)

func _build_main_panel():
	var panel = PanelContainer.new()
	panel.position = Vector2(48, 135)
	panel.size = Vector2(480, 555)
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	panel.add_child(box)
	box.add_child(make_label("БОЙ 4 × 4", 28))
	map_status = make_label("", 16, Color("b8c9d8"))
	map_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_status.custom_minimum_size = Vector2(420, 43)
	box.add_child(map_status)

	var map_row = HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 8)
	box.add_child(map_row)
	var map_group = ButtonGroup.new()
	for id in SaveData.MAP_IDS:
		var button = Button.new()
		button.toggle_mode = true
		button.button_group = map_group
		button.text = SaveData.map_catalog()[id].name.to_upper()
		button.custom_minimum_size = Vector2(205, 42)
		style_button(button, Color("23e6ff") if id == "farm" else Color("ff9f1c"))
		button.pressed.connect(_select_map.bind(id))
		map_row.add_child(button)
		map_buttons[id] = button

	var nick_row = HBoxContainer.new()
	nick_row.add_theme_constant_override("separation", 8)
	box.add_child(nick_row)
	nickname_input = LineEdit.new()
	nickname_input.placeholder_text = "Никнейм / Nickname"
	nickname_input.max_length = 18
	nickname_input.custom_minimum_size = Vector2(282, 40)
	nickname_input.add_theme_font_size_override("font_size", 19)
	nick_row.add_child(nickname_input)
	var save_nick = Button.new()
	save_nick.text = "СОХРАНИТЬ"
	save_nick.custom_minimum_size = Vector2(130, 40)
	style_button(save_nick, Color("8cff98"))
	save_nick.pressed.connect(_save_nickname)
	nick_row.add_child(save_nick)
	nickname_status = make_label("Русские и английские символы поддерживаются", 13, Color("7893a8"))
	box.add_child(nickname_status)

	start_button = Button.new()
	start_button.text = "НАЧАТЬ БОЙ"
	start_button.custom_minimum_size = Vector2(420, 54)
	style_button(start_button, Color("23e6ff"))
	start_button.pressed.connect(func(): start_match.emit())
	box.add_child(start_button)
	start_status = make_label("", 14, Color("8cff98"))
	start_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_status.custom_minimum_size = Vector2(420, 24)
	box.add_child(start_status)
	var shop = Button.new()
	shop.text = "МАГАЗИН И СНАРЯЖЕНИЕ"
	shop.custom_minimum_size = Vector2(420, 40)
	style_button(shop, Color("ffca3a"))
	shop.pressed.connect(_show_shop)
	box.add_child(shop)
	var settings = Button.new()
	settings.text = "⚙  НАСТРОЙКИ"
	settings.custom_minimum_size = Vector2(420, 40)
	style_button(settings, Color("b48cff"))
	settings.pressed.connect(_show_settings)
	box.add_child(settings)
	var admin = Button.new()
	admin.text = "АДМИН • ТЕСТОВЫЕ МОНЕТЫ"
	admin.custom_minimum_size = Vector2(420, 40)
	style_button(admin, Color("ef476f"))
	admin.pressed.connect(_show_admin)
	box.add_child(admin)
	loadout_status = make_label("", 14, Color("d8e6f0"))
	loadout_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_status.custom_minimum_size = Vector2(420, 58)
	box.add_child(loadout_status)

func show_start_loading():
	if is_instance_valid(start_button):
		start_button.disabled = true
		start_button.text = "ЗАГРУЗКА БОЯ..."
	if is_instance_valid(start_status):
		start_status.text = "Создаём карту, бойцов и интерфейс"
		start_status.add_theme_color_override("font_color", Color("8cff98"))

func show_start_error(message):
	if is_instance_valid(start_button):
		start_button.disabled = false
		start_button.text = "НАЧАТЬ БОЙ"
	if is_instance_valid(start_status):
		start_status.text = str(message)
		start_status.add_theme_color_override("font_color", Color("ef476f"))

func _build_shop():
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(555, 135)
	shop_panel.size = Vector2(675, 525)
	shop_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(shop_panel)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	shop_panel.add_child(root)
	root.add_child(make_label("МАГАЗИН", 28, Color("ffca3a")))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	content.add_child(make_label("Сначала выбери один из четырёх оружейных слотов:", 17, Color("9db4c7")))
	var slots = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	content.add_child(slots)
	for i in range(4):
		var button = Button.new()
		button.custom_minimum_size = Vector2(145, 55)
		style_button(button)
		button.pressed.connect(_select_slot.bind(i))
		slots.add_child(button)
		slot_buttons.append(button)
	var clear_button = Button.new()
	clear_button.text = "ОЧИСТИТЬ ВЫБРАННЫЙ СЛОТ"
	clear_button.custom_minimum_size = Vector2(610, 40)
	style_button(clear_button, Color("ef476f"))
	clear_button.pressed.connect(func():
		SaveData.equip_weapon("", active_slot)
		refresh()
	)
	content.add_child(clear_button)

	content.add_child(make_label("ОРУЖИЕ", 22, Color("23e6ff")))
	var cards = GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	content.add_child(cards)
	for id in SaveData.main_weapon_ids():
		var card = _create_weapon_card(id)
		cards.add_child(card)
		weapon_cards[id] = card

	content.add_child(make_label("СНАРЯЖЕНИЕ", 22, Color("77d8ff")))
	content.add_child(_create_armor_card())
	content.add_child(_create_helmet_card())
	content.add_child(make_label("РАСХОДНИКИ", 22, Color("8cff98")))
	content.add_child(_create_consumables_card())

func _create_icon(id, accent):
	var icon = StoreIconScript.new()
	icon.configure(id, accent)
	return icon

func _create_weapon_card(id):
	var catalog = SaveData.weapon_catalog()[id]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(299, 330)
	card.add_theme_stylebox_override("panel", panel_style(Color("102436")))
	var box = VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 5)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	card.add_child(box)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 9)
	box.add_child(header)
	header.add_child(_create_icon(id, catalog.color))
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(make_label(catalog.name, 19, catalog.color))
	title_box.add_child(make_label("Открытие: уровень %d" % int(catalog.unlock_level), 14, Color("9db4c7")))
	var info = make_label("", 14, Color("b8c9d8"))
	info.name = "Info"
	info.custom_minimum_size = Vector2(270, 105)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var action = Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(270, 38)
	style_button(action, catalog.color)
	action.pressed.connect(_weapon_action.bind(id))
	box.add_child(action)
	var upgrade = Button.new()
	upgrade.name = "Upgrade"
	upgrade.custom_minimum_size = Vector2(270, 36)
	style_button(upgrade, Color("8cff98"))
	upgrade.pressed.connect(func():
		SaveData.upgrade_weapon(id)
		refresh()
	)
	box.add_child(upgrade)
	return card

func _create_armor_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 132)
	card.add_theme_stylebox_override("panel", panel_style(Color("102b33")))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	card.add_child(row)
	row.add_child(_create_icon("armor", Color("77d8ff")))
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(make_label("БРОНЯ", 21, Color("77d8ff")))
	armor_info = make_label("", 15, Color("b8c9d8"))
	armor_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(armor_info)
	armor_button = Button.new()
	armor_button.custom_minimum_size = Vector2(205, 70)
	style_button(armor_button, Color("77d8ff"))
	armor_button.pressed.connect(func():
		SaveData.buy_or_upgrade_armor()
		refresh()
	)
	row.add_child(armor_button)
	return card

func _create_helmet_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 122)
	card.add_theme_stylebox_override("panel", panel_style(Color("1b2630")))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	card.add_child(row)
	row.add_child(_create_icon("helmet", Color("d8e6f0")))
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(make_label("ТАКТИЧЕСКАЯ КАСКА", 21, Color("d8e6f0")))
	helmet_info = make_label("Снижает урон от попаданий в голову на 50%.", 15, Color("b8c9d8"))
	helmet_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(helmet_info)
	helmet_button = Button.new()
	helmet_button.custom_minimum_size = Vector2(205, 66)
	style_button(helmet_button, Color("d8e6f0"))
	helmet_button.pressed.connect(func():
		SaveData.buy_helmet()
		refresh()
	)
	row.add_child(helmet_button)
	return card

func _create_consumables_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 230)
	card.add_theme_stylebox_override("panel", panel_style(Color("102a24")))
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	card.add_child(box)
	consumable_info = make_label("", 15, Color("b8c9d8"))
	consumable_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(consumable_info)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var med_box = VBoxContainer.new()
	med_box.custom_minimum_size = Vector2(290, 150)
	row.add_child(med_box)
	med_box.add_child(_create_icon("medkit", Color("ef476f")))
	medkit_button = Button.new()
	style_button(medkit_button, Color("ef476f"))
	medkit_button.pressed.connect(func():
		SaveData.buy_consumable("medkit")
		refresh()
	)
	med_box.add_child(medkit_button)
	var grenade_box = VBoxContainer.new()
	grenade_box.custom_minimum_size = Vector2(290, 150)
	row.add_child(grenade_box)
	grenade_box.add_child(_create_icon("grenade", Color("ff8a24")))
	grenade_button = Button.new()
	style_button(grenade_button, Color("ff8a24"))
	grenade_button.pressed.connect(func():
		SaveData.buy_consumable("grenade")
		refresh()
	)
	grenade_box.add_child(grenade_button)
	return card

func _build_settings():
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(555, 135)
	settings_panel.size = Vector2(675, 525)
	settings_panel.add_theme_stylebox_override("panel", panel_style(Color("151128")))
	add_child(settings_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 25)
	settings_panel.add_child(box)
	box.add_child(make_label("НАСТРОЙКИ", 30, Color("b48cff")))
	sensitivity_label = make_label("", 20, Color("d8e6f0"))
	box.add_child(sensitivity_label)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.55
	sensitivity_slider.max_value = 1.8
	sensitivity_slider.step = 0.05
	sensitivity_slider.custom_minimum_size = Vector2(600, 40)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	box.add_child(sensitivity_slider)
	box.add_child(make_label("ПЛАВНОСТЬ", 20, Color("d8e6f0")))
	var fps_row = HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 14)
	box.add_child(fps_row)
	var fps_group = ButtonGroup.new()
	for fps in SaveData.ALLOWED_FPS:
		var button = Button.new()
		button.text = "%d FPS" % fps
		button.toggle_mode = true
		button.button_group = fps_group
		button.custom_minimum_size = Vector2(190, 52)
		style_button(button, Color("8cff98") if fps == 60 else Color("23e6ff"))
		button.pressed.connect(_on_fps_selected.bind(fps))
		fps_row.add_child(button)
		fps_buttons[fps] = button
	box.add_child(make_label("КАЧЕСТВО ГРАФИКИ", 20, Color("d8e6f0")))
	var graphics_row = HBoxContainer.new()
	graphics_row.add_theme_constant_override("separation", 14)
	box.add_child(graphics_row)
	var graphics_group = ButtonGroup.new()
	for quality in SaveData.GRAPHICS_QUALITIES:
		var button = Button.new()
		button.text = {"low": "НИЗКАЯ", "medium": "СРЕДНЯЯ", "high": "ВЫСОКАЯ"}[quality]
		button.toggle_mode = true
		button.button_group = graphics_group
		button.custom_minimum_size = Vector2(190, 50)
		style_button(button, Color("ffca3a"))
		button.pressed.connect(_on_graphics_selected.bind(quality))
		graphics_row.add_child(button)
		graphics_buttons[quality] = button
	aim_toggle = CheckButton.new()
	aim_toggle.text = "AIM — мягкая помощь при наведении"
	aim_toggle.add_theme_font_size_override("font_size", 19)
	aim_toggle.toggled.connect(_on_aim_toggled)
	box.add_child(aim_toggle)
	auto_toggle = CheckButton.new()
	auto_toggle.text = "Автострельба при наведении"
	auto_toggle.add_theme_font_size_override("font_size", 19)
	auto_toggle.toggled.connect(_on_auto_toggled)
	box.add_child(auto_toggle)
	fps_counter_toggle = CheckButton.new()
	fps_counter_toggle.text = "Показывать счётчик FPS"
	fps_counter_toggle.add_theme_font_size_override("font_size", 19)
	fps_counter_toggle.toggled.connect(_on_fps_counter_toggled)
	box.add_child(fps_counter_toggle)
	var back = Button.new()
	back.text = "ВЕРНУТЬСЯ В МАГАЗИН"
	back.custom_minimum_size = Vector2(600, 50)
	style_button(back, Color("ffca3a"))
	back.pressed.connect(_show_shop)
	box.add_child(back)

func _build_admin():
	admin_panel = PanelContainer.new()
	admin_panel.position = Vector2(555, 135)
	admin_panel.size = Vector2(675, 525)
	admin_panel.add_theme_stylebox_override("panel", panel_style(Color("1d111a")))
	add_child(admin_panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 30)
	admin_panel.add_child(box)
	box.add_child(make_label("АДМИН-ПАНЕЛЬ", 31, Color("ef476f")))
	box.add_child(make_label("Локальная тестовая функция для быстрой проверки магазина.", 18, Color("d8e6f0")))
	admin_coins = SpinBox.new()
	admin_coins.min_value = 0
	admin_coins.max_value = 999999999
	admin_coins.step = 1
	admin_coins.allow_greater = true
	admin_coins.custom_minimum_size = Vector2(600, 58)
	admin_coins.add_theme_font_size_override("font_size", 24)
	box.add_child(admin_coins)
	var set_button = Button.new()
	set_button.text = "УСТАНОВИТЬ МОНЕТЫ"
	set_button.custom_minimum_size = Vector2(600, 58)
	style_button(set_button, Color("ef476f"))
	set_button.pressed.connect(_admin_set_coins)
	box.add_child(set_button)
	var quick = HBoxContainer.new()
	quick.add_theme_constant_override("separation", 12)
	box.add_child(quick)
	for amount in [1000, 10000, 100000]:
		var button = Button.new()
		button.text = "+%d" % amount
		button.custom_minimum_size = Vector2(190, 50)
		style_button(button, Color("ffca3a"))
		button.pressed.connect(_admin_add_coins.bind(amount))
		quick.add_child(button)
	admin_status = make_label("", 19, Color("8cff98"))
	admin_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(admin_status)
	var back = Button.new()
	back.text = "ВЕРНУТЬСЯ В МАГАЗИН"
	back.custom_minimum_size = Vector2(600, 54)
	style_button(back, Color("23e6ff"))
	back.pressed.connect(_show_shop)
	box.add_child(back)

func _show_shop():
	shop_panel.visible = true
	settings_panel.visible = false
	admin_panel.visible = false
	refresh()

func _show_settings():
	shop_panel.visible = false
	settings_panel.visible = true
	admin_panel.visible = false
	refresh()

func _show_admin():
	shop_panel.visible = false
	settings_panel.visible = false
	admin_panel.visible = true
	admin_coins.value = SaveData.coins
	admin_status.text = ""
	refresh()

func _select_map(id):
	SaveData.set_selected_map(id)
	refresh()

func _select_slot(index):
	active_slot = index
	refresh()

func _weapon_action(id):
	if not SaveData.is_weapon_unlocked(id):
		return
	if not SaveData.owned_weapons.get(id, false):
		SaveData.buy_weapon(id)
	else:
		SaveData.equip_weapon(id, active_slot)
	refresh()

func _save_nickname():
	SaveData.set_nickname(nickname_input.text)
	nickname_status.text = "Сохранено: %s" % SaveData.nickname
	refresh()

func refresh():
	if not is_instance_valid(coins_label):
		return
	coins_label.text = "МОНЕТЫ  ◈  %d" % SaveData.coins
	profile_label.text = "%s • УРОВЕНЬ %d/5 • %s" % [SaveData.nickname, SaveData.player_level, SaveData.xp_progress_text()]
	if not nickname_input.has_focus():
		nickname_input.text = SaveData.nickname
	var map_data = SaveData.map_catalog()[SaveData.selected_map]
	map_status.text = "%s • %s\n%s" % [map_data.name, map_data.mode, map_data.description]
	for id in map_buttons:
		map_buttons[id].set_pressed_no_signal(id == SaveData.selected_map)

	var equipped_names = []
	for i in range(slot_buttons.size()):
		var id = SaveData.loadout[i]
		var weapon_name = "ПУСТО"
		if id != "":
			weapon_name = SaveData.weapon_catalog()[id].type
			equipped_names.append(SaveData.weapon_catalog()[id].name)
		slot_buttons[i].text = "%sСЛОТ %d\n%s" % ["> " if active_slot == i else "", i + 1, weapon_name]
	var equipment_text = ", ".join(equipped_names) if not equipped_names.is_empty() else "нет основного оружия"
	loadout_status.text = "Оружие: %s\nHP %d • броня %d • каска %s • аптечки %d • гранаты %d" % [equipment_text, SaveData.player_max_health(), SaveData.armor_capacity(), "есть" if SaveData.helmet_owned else "нет", SaveData.medkits, SaveData.grenades]

	for id in weapon_cards:
		var card = weapon_cards[id]
		var catalog = SaveData.weapon_catalog()[id]
		var stats = SaveData.get_weapon_stats(id)
		var level = int(stats.level)
		var owned = bool(SaveData.owned_weapons.get(id, false))
		var unlocked = SaveData.is_weapon_unlocked(id)
		var info = card.get_node("Content/Info")
		var damage_text = "%.0f × %d дробин" % [float(stats.damage), int(stats.pellets)] if id == "shotgun" else "%.0f" % float(stats.damage)
		info.text = "%s • ур.%d/5 • мощь %d\nУрон %s • голова ×%.2f\nДальность %d • магазин %d\nТемп %.2fс • перезарядка %.0fс" % [catalog.type, level, int(stats.power), damage_text, float(stats.headshot_multiplier), int(stats.range), int(catalog.magazine), float(catalog.fire_rate), float(catalog.reload_time)]
		var action = card.get_node("Content/Action")
		if not unlocked:
			action.text = "ОТКРОЕТСЯ НА УРОВНЕ %d" % int(catalog.unlock_level)
			action.disabled = true
		elif owned:
			action.text = "ПОСТАВИТЬ В СЛОТ %d" % (active_slot + 1)
			action.disabled = false
		else:
			action.text = "КУПИТЬ ЗА %d" % int(catalog.price)
			action.disabled = SaveData.coins < int(catalog.price)
		var upgrade = card.get_node("Content/Upgrade")
		if not owned:
			upgrade.text = "СНАЧАЛА КУПИТЬ"
			upgrade.disabled = true
		elif level >= 5:
			upgrade.text = "МАКСИМАЛЬНЫЙ УРОВЕНЬ"
			upgrade.disabled = true
		else:
			upgrade.text = "УЛУЧШИТЬ ДО %d ЗА %d" % [level + 1, SaveData.upgrade_cost(id)]
			upgrade.disabled = SaveData.coins < SaveData.upgrade_cost(id)
	_refresh_armor()
	_refresh_helmet()
	consumable_info.text = "Аптечки: %d — +10 HP, максимум 10 за жизнь. Гранаты: %d — 100 урона, максимум 2 за жизнь." % [SaveData.medkits, SaveData.grenades]
	medkit_button.text = "КУПИТЬ АПТЕЧКУ\n%d МОНЕТ" % SaveData.MEDKIT_PRICE
	grenade_button.text = "КУПИТЬ ГРАНАТУ\n%d МОНЕТ" % SaveData.GRENADE_PRICE
	medkit_button.disabled = SaveData.coins < SaveData.MEDKIT_PRICE
	grenade_button.disabled = SaveData.coins < SaveData.GRENADE_PRICE
	sensitivity_label.text = "ЧУВСТВИТЕЛЬНОСТЬ СЕНСОРА: %.2f" % SaveData.look_sensitivity
	sensitivity_slider.set_value_no_signal(SaveData.look_sensitivity)
	for fps in fps_buttons:
		fps_buttons[fps].set_pressed_no_signal(int(fps) == SaveData.target_fps)
	for quality in graphics_buttons:
		graphics_buttons[quality].set_pressed_no_signal(str(quality) == SaveData.graphics_quality)
	auto_toggle.set_pressed_no_signal(SaveData.auto_fire)
	aim_toggle.set_pressed_no_signal(SaveData.aim_assist)
	fps_counter_toggle.set_pressed_no_signal(SaveData.show_fps)
	if is_instance_valid(admin_coins) and not admin_coins.has_focus():
		admin_coins.value = SaveData.coins

func _refresh_armor():
	var capacity = SaveData.armor_capacity()
	if SaveData.armor_level >= SaveData.ARMOR_COSTS.size():
		armor_info.text = "Максимальная броня: %d. Сначала расходуется броня, затем HP." % capacity
		armor_button.text = "МАКСИМУМ\n%d БРОНИ" % capacity
		armor_button.disabled = true
		return
	var next_capacity = SaveData.ARMOR_CAPACITIES[SaveData.armor_level + 1]
	var price = SaveData.armor_next_cost()
	var need_level = SaveData.armor_next_unlock_level()
	armor_info.text = "Сейчас %d брони. Следующее улучшение: %d брони, требуется уровень %d." % [capacity, next_capacity, need_level]
	if SaveData.player_level < need_level:
		armor_button.text = "НУЖЕН УРОВЕНЬ %d" % need_level
		armor_button.disabled = true
	else:
		armor_button.text = "ДО %d БРОНИ\nЗА %d" % [next_capacity, price]
		armor_button.disabled = SaveData.coins < price

func _refresh_helmet():
	if SaveData.helmet_owned:
		helmet_info.text = "Каска надета. Урон от попаданий в голову снижен на 50%."
		helmet_button.text = "КУПЛЕНО"
		helmet_button.disabled = true
	elif SaveData.player_level < SaveData.HELMET_UNLOCK_LEVEL:
		helmet_info.text = "Снижает урон в голову на 50%. Откроется на уровне 3."
		helmet_button.text = "НУЖЕН УРОВЕНЬ 3"
		helmet_button.disabled = true
	else:
		helmet_info.text = "Снижает урон от каждого попадания в голову на 50%."
		helmet_button.text = "КУПИТЬ\nЗА %d" % SaveData.HELMET_PRICE
		helmet_button.disabled = SaveData.coins < SaveData.HELMET_PRICE

func _admin_set_coins():
	SaveData.set_coins(int(admin_coins.value))
	admin_status.text = "Установлено: %d монет" % SaveData.coins
	refresh()

func _admin_add_coins(amount):
	SaveData.add_coins(amount)
	admin_status.text = "Добавлено %d монет" % amount
	refresh()

func _on_sensitivity_changed(value):
	SaveData.look_sensitivity = float(value)
	SaveData.save_game()
	refresh()

func _on_fps_selected(fps):
	SaveData.set_target_fps(int(fps))
	refresh()

func _on_graphics_selected(quality):
	SaveData.set_graphics_quality(str(quality))
	refresh()

func _on_auto_toggled(value):
	SaveData.auto_fire = bool(value)
	SaveData.save_game()

func _on_aim_toggled(value):
	SaveData.aim_assist = bool(value)
	SaveData.save_game()

func _on_fps_counter_toggled(value):
	SaveData.show_fps = bool(value)
	SaveData.save_game()
