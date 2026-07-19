extends Control

signal start_match

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
var medkit_button
var grenade_button
var consumable_info
var sensitivity_label
var sensitivity_slider
var fps_buttons = {}
var graphics_buttons = {}
var auto_toggle
var aim_toggle
var fps_counter_toggle
var loadout_status
var admin_coins
var admin_status

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
	button.add_theme_font_size_override("font_size", 20)
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
	var subtitle = make_label("МОБИЛЬНЫЙ FPS • ПРОТОТИП 0.7", 18, Color("9db4c7"))
	subtitle.position = Vector2(51, 83)
	add_child(subtitle)
	coins_label = make_label("", 28, Color("ffca3a"))
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.position = Vector2(930, 34)
	coins_label.size = Vector2(300, 42)
	add_child(coins_label)
	profile_label = make_label("", 18, Color("8cff98"))
	profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile_label.position = Vector2(770, 78)
	profile_label.size = Vector2(460, 34)
	add_child(profile_label)

func _build_main_panel():
	var panel = PanelContainer.new()
	panel.position = Vector2(48, 135)
	panel.size = Vector2(480, 525)
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	panel.add_child(box)
	box.add_child(make_label("КОМАНДНЫЙ БОЙ 4 × 4", 28))
	var desc = make_label("Первыми набери 25 устранений. После матча получаешь монеты, опыт и полную статистику.", 17, Color("b8c9d8"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(420, 47)
	box.add_child(desc)

	var nick_row = HBoxContainer.new()
	nick_row.add_theme_constant_override("separation", 8)
	box.add_child(nick_row)
	nickname_input = LineEdit.new()
	nickname_input.placeholder_text = "Никнейм / Nickname"
	nickname_input.max_length = 18
	nickname_input.custom_minimum_size = Vector2(282, 42)
	nickname_input.add_theme_font_size_override("font_size", 19)
	nick_row.add_child(nickname_input)
	var save_nick = Button.new()
	save_nick.text = "СОХРАНИТЬ"
	save_nick.custom_minimum_size = Vector2(130, 42)
	style_button(save_nick, Color("8cff98"))
	save_nick.pressed.connect(_save_nickname)
	nick_row.add_child(save_nick)
	nickname_status = make_label("Можно писать по-русски и по-английски", 14, Color("7893a8"))
	box.add_child(nickname_status)

	var start = Button.new()
	start.text = "НАЧАТЬ БОЙ"
	start.custom_minimum_size = Vector2(420, 56)
	style_button(start, Color("23e6ff"))
	start.pressed.connect(func(): start_match.emit())
	box.add_child(start)
	var shop = Button.new()
	shop.text = "АРСЕНАЛ, БРОНЯ И ПРЕДМЕТЫ"
	shop.custom_minimum_size = Vector2(420, 42)
	style_button(shop, Color("ffca3a"))
	shop.pressed.connect(_show_shop)
	box.add_child(shop)
	var settings = Button.new()
	settings.text = "⚙  НАСТРОЙКИ"
	settings.custom_minimum_size = Vector2(420, 42)
	style_button(settings, Color("b48cff"))
	settings.pressed.connect(_show_settings)
	box.add_child(settings)
	var admin = Button.new()
	admin.text = "АДМИН • ТЕСТОВЫЕ МОНЕТЫ"
	admin.custom_minimum_size = Vector2(420, 42)
	style_button(admin, Color("ef476f"))
	admin.pressed.connect(_show_admin)
	box.add_child(admin)
	box.add_child(make_label("ТЕКУЩЕЕ СНАРЯЖЕНИЕ", 16, Color("9db4c7")))
	loadout_status = make_label("", 15, Color("d8e6f0"))
	loadout_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loadout_status.custom_minimum_size = Vector2(420, 46)
	box.add_child(loadout_status)

func _build_shop():
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(555, 135)
	shop_panel.size = Vector2(675, 525)
	shop_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(shop_panel)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	shop_panel.add_child(root)
	root.add_child(make_label("АРСЕНАЛ И СНАРЯЖЕНИЕ", 28, Color("ffca3a")))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 0)
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	content.add_child(make_label("Выбери слот, затем оружие:", 18, Color("9db4c7")))
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
	clear_button.custom_minimum_size = Vector2(610, 42)
	style_button(clear_button, Color("ef476f"))
	clear_button.pressed.connect(func():
		SaveData.equip_weapon("", active_slot)
		refresh()
	)
	content.add_child(clear_button)
	var cards = GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	content.add_child(cards)
	for id in SaveData.main_weapon_ids():
		var card = _create_weapon_card(id)
		cards.add_child(card)
		weapon_cards[id] = card
	content.add_child(_create_armor_card())
	content.add_child(_create_consumables_card())
	var note = make_label("Дальность: автомат 20, дробовик 10, пулемёт 35, снайперская винтовка 70 шагов.", 15, Color("7893a8"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(610, 42)
	content.add_child(note)

func _create_weapon_card(id):
	var catalog = SaveData.weapon_catalog()[id]
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(299, 280)
	card.add_theme_stylebox_override("panel", panel_style(Color("102436")))
	var box = VBoxContainer.new()
	box.name = "Content"
	box.add_theme_constant_override("separation", 5)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	card.add_child(box)
	box.add_child(make_label(catalog.name, 20, catalog.color))
	var info = make_label("", 15, Color("b8c9d8"))
	info.name = "Info"
	info.custom_minimum_size = Vector2(270, 128)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	var action = Button.new()
	action.name = "Action"
	action.custom_minimum_size = Vector2(270, 40)
	style_button(action, catalog.color)
	action.pressed.connect(_weapon_action.bind(id))
	box.add_child(action)
	var upgrade = Button.new()
	upgrade.name = "Upgrade"
	upgrade.custom_minimum_size = Vector2(270, 38)
	style_button(upgrade, Color("8cff98"))
	upgrade.pressed.connect(func():
		SaveData.upgrade_weapon(id)
		refresh()
	)
	box.add_child(upgrade)
	return card

func _create_armor_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 122)
	card.add_theme_stylebox_override("panel", panel_style(Color("102b33")))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	card.add_child(row)
	var text_box = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	text_box.add_child(make_label("БРОНЯ", 22, Color("77d8ff")))
	armor_info = make_label("", 16, Color("b8c9d8"))
	armor_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(armor_info)
	armor_button = Button.new()
	armor_button.custom_minimum_size = Vector2(235, 68)
	style_button(armor_button, Color("77d8ff"))
	armor_button.pressed.connect(func():
		SaveData.buy_or_upgrade_armor()
		refresh()
	)
	row.add_child(armor_button)
	return card

func _create_consumables_card():
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(610, 174)
	card.add_theme_stylebox_override("panel", panel_style(Color("18251e")))
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	card.add_child(box)
	box.add_child(make_label("РАСХОДНИКИ", 22, Color("8cff98")))
	consumable_info = make_label("", 16, Color("b8c9d8"))
	box.add_child(consumable_info)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	medkit_button = Button.new()
	medkit_button.custom_minimum_size = Vector2(288, 62)
	style_button(medkit_button, Color("8cff98"))
	medkit_button.pressed.connect(func():
		SaveData.buy_consumable("medkit")
		refresh()
	)
	row.add_child(medkit_button)
	grenade_button = Button.new()
	grenade_button.custom_minimum_size = Vector2(288, 62)
	style_button(grenade_button, Color("ff8a24"))
	grenade_button.pressed.connect(func():
		SaveData.buy_consumable("grenade")
		refresh()
	)
	row.add_child(grenade_button)
	return card

func _build_settings():
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(555, 135)
	settings_panel.size = Vector2(675, 525)
	settings_panel.add_theme_stylebox_override("panel", panel_style(Color("0b1825")))
	add_child(settings_panel)
	var outer = VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	settings_panel.add_child(outer)
	outer.add_child(make_label("⚙  НАСТРОЙКИ", 30, Color("b48cff")))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(610, 0)
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)
	sensitivity_label = make_label("", 20, Color("d8e6f0"))
	box.add_child(sensitivity_label)
	sensitivity_slider = HSlider.new()
	sensitivity_slider.min_value = 0.55
	sensitivity_slider.max_value = 1.8
	sensitivity_slider.step = 0.05
	sensitivity_slider.custom_minimum_size = Vector2(600, 36)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	box.add_child(sensitivity_slider)
	box.add_child(make_label("ПЛАВНОСТЬ — ЛИМИТ FPS", 20, Color("d8e6f0")))
	var fps_row = HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 14)
	box.add_child(fps_row)
	var fps_group = ButtonGroup.new()
	for fps in SaveData.ALLOWED_FPS:
		var button = Button.new()
		button.text = "%d FPS" % fps
		button.toggle_mode = true
		button.button_group = fps_group
		button.custom_minimum_size = Vector2(190, 56)
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
		button.custom_minimum_size = Vector2(190, 54)
		style_button(button, Color("ffca3a"))
		button.pressed.connect(_on_graphics_selected.bind(quality))
		graphics_row.add_child(button)
		graphics_buttons[quality] = button
	aim_toggle = CheckButton.new()
	aim_toggle.text = "AIM — мягкая помощь при наведении"
	aim_toggle.add_theme_font_size_override("font_size", 20)
	aim_toggle.toggled.connect(_on_aim_toggled)
	box.add_child(aim_toggle)
	auto_toggle = CheckButton.new()
	auto_toggle.text = "Автострельба при наведении на противника"
	auto_toggle.add_theme_font_size_override("font_size", 20)
	auto_toggle.toggled.connect(_on_auto_toggled)
	box.add_child(auto_toggle)
	fps_counter_toggle = CheckButton.new()
	fps_counter_toggle.text = "Показывать счётчик FPS в бою"
	fps_counter_toggle.add_theme_font_size_override("font_size", 20)
	fps_counter_toggle.toggled.connect(_on_fps_counter_toggled)
	box.add_child(fps_counter_toggle)
	var note = make_label("AIM не фиксирует прицел жёстко: он только слегка доводит камеру к ближайшей цели.", 16, Color("7893a8"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	var back = Button.new()
	back.text = "ВЕРНУТЬСЯ В АРСЕНАЛ"
	back.custom_minimum_size = Vector2(600, 54)
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
	var warning = make_label("Локальная тестовая функция. Введи нужное количество монет.", 18, Color("d8e6f0"))
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warning)
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
	back.text = "ВЕРНУТЬСЯ В АРСЕНАЛ"
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
	var xp_text = "МАКС. УРОВЕНЬ" if SaveData.player_level >= 2 else "%d / %d XP" % [SaveData.experience, SaveData.LEVEL_2_XP]
	profile_label.text = "%s • УРОВЕНЬ %d • %s" % [SaveData.nickname, SaveData.player_level, xp_text]
	if not nickname_input.has_focus():
		nickname_input.text = SaveData.nickname
	var equipped_names = []
	for i in range(slot_buttons.size()):
		var id = SaveData.loadout[i]
		var weapon_name = "ПУСТО"
		if id != "":
			weapon_name = SaveData.weapon_catalog()[id].type
			equipped_names.append(weapon_name)
		slot_buttons[i].text = "%sСЛОТ %d\n%s" % ["> " if active_slot == i else "", i + 1, weapon_name]
	var equipment_text = ", ".join(equipped_names) if not equipped_names.is_empty() else "нет основного оружия"
	loadout_status.text = "Оружие: %s\nHP %d • броня %d • аптечки %d • гранаты %d" % [equipment_text, SaveData.player_max_health(), SaveData.armor_capacity(), SaveData.medkits, SaveData.grenades]
	for id in weapon_cards:
		var card = weapon_cards[id]
		var catalog = SaveData.weapon_catalog()[id]
		var stats = SaveData.get_weapon_stats(id)
		var level = int(stats.level)
		var owned = bool(SaveData.owned_weapons.get(id, false))
		var unlocked = SaveData.is_weapon_unlocked(id)
		var info = card.get_node("Content/Info")
		var head_damage = float(stats.damage) * float(stats.headshot_multiplier)
		var damage_text = "урон %.0f × %d дробин" % [float(stats.damage), int(stats.pellets)] if id == "shotgun" else "урон %.0f" % float(stats.damage)
		info.text = "%s • уровень %d/5\nМощь %d • %s\nВ голову %.0f • дальность %d\nМагазин %d • отдача разная" % [catalog.type, level, int(stats.power), damage_text, head_damage, int(stats.range), int(catalog.magazine)]
		var action = card.get_node("Content/Action")
		if not unlocked:
			action.text = "ОТКРОЕТСЯ НА УРОВНЕ %d" % int(catalog.unlock_level)
			action.disabled = true
		elif owned:
			action.text = "ПОСТАВИТЬ В СЛОТ %d" % (active_slot + 1)
			action.disabled = false
		else:
			action.text = "КУПИТЬ ЗА %d" % int(catalog.price)
			action.disabled = false
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
	_refresh_armor()
	consumable_info.text = "Аптечки: %d (лечат +10 HP, до 10 за жизнь) • гранаты: %d (100 урона, до 2 за жизнь)" % [SaveData.medkits, SaveData.grenades]
	medkit_button.text = "КУПИТЬ 1 АПТЕЧКУ\n%d МОНЕТ" % SaveData.MEDKIT_PRICE
	grenade_button.text = "КУПИТЬ 1 ГРАНАТУ\n%d МОНЕТ" % SaveData.GRENADE_PRICE
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
	if SaveData.armor_level >= 3:
		armor_info.text = "Максимальная броня: 300. Сначала расходуется броня, затем HP."
		armor_button.text = "МАКСИМУМ\n300 БРОНИ"
		armor_button.disabled = true
	elif SaveData.armor_level >= 1 and SaveData.player_level < 2:
		armor_info.text = "Сейчас %d брони. Улучшения до 200 и 300 откроются на уровне 2." % capacity
		armor_button.text = "НУЖЕН УРОВЕНЬ 2"
		armor_button.disabled = true
	else:
		var next_capacity = SaveData.ARMOR_CAPACITIES[SaveData.armor_level + 1]
		var price = SaveData.armor_next_cost()
		armor_info.text = "Сейчас %d брони. Следующее улучшение даст %d." % [capacity, next_capacity]
		armor_button.text = "УЛУЧШИТЬ ДО %d\nЗА %d" % [next_capacity, price]
		armor_button.disabled = false

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
