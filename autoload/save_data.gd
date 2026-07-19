extends Node

const SAVE_PATH = "user://boom_arena_save.json"
const ARMOR_PRICE = 500
const ARMOR_VALUE = 100
const ALLOWED_FPS = [30, 60, 120]

var coins = 800
var owned_weapons = {"rifle": true, "shotgun": false}
var weapon_levels = {"rifle": 1, "shotgun": 1}
var loadout = ["rifle", "", "", ""]
var armor_owned = false
var auto_fire = true
var look_sensitivity = 1.0
var target_fps = 60
var selected_loadout_slot = 0

func _ready():
	load_game()
	apply_runtime_settings()

func weapon_catalog():
	return {
		"rifle": {
			"name": "AR-4 Новобранец",
			"type": "Автомат",
			"price": 0,
			"damage_levels": [12.0, 15.0, 19.0, 24.0, 30.0],
			"power_levels": [20, 28, 38, 50, 65],
			"upgrade_costs": [300, 500, 900, 1500],
			"headshot_multiplier": 1.8,
			"fire_rate": 0.11,
			"magazine": 30,
			"reserve": 120,
			"range": 55.0,
			"spread": 0.014,
			"pellets": 1,
			"color": Color("23e6ff")
		},
		"shotgun": {
			"name": "SG-12 Гром",
			"type": "Дробовик",
			"price": 500,
			"damage_levels": [9.0, 10.0, 11.5, 13.0, 15.0],
			"power_levels": [34, 40, 48, 57, 68],
			"upgrade_costs": [400, 650, 1000, 1600],
			"headshot_multiplier": 1.35,
			"fire_rate": 0.78,
			"magazine": 6,
			"reserve": 30,
			"range": 22.0,
			"spread": 0.085,
			"pellets": 8,
			"color": Color("ffca3a")
		},
		"pistol": {
			"name": "P-9 Резерв",
			"type": "Пистолет",
			"price": 0,
			"damage_levels": [18.0],
			"power_levels": [26],
			"upgrade_costs": [],
			"headshot_multiplier": 1.55,
			"fire_rate": 0.28,
			"magazine": 12,
			"reserve": 48,
			"range": 42.0,
			"spread": 0.02,
			"pellets": 1,
			"color": Color("eeeeee")
		}
	}

func get_weapon_stats(id, level_override = -1):
	var catalog = weapon_catalog()
	if not catalog.has(id):
		return {}
	var data = catalog[id].duplicate(true)
	var level = 1
	if id != "pistol":
		level = int(level_override) if int(level_override) > 0 else int(weapon_levels.get(id, 1))
	level = clampi(level, 1, 5)
	var damage_levels = data.get("damage_levels", [1.0])
	var power_levels = data.get("power_levels", [1])
	var stat_index = mini(level - 1, damage_levels.size() - 1)
	data.damage = float(damage_levels[stat_index])
	data.power = int(power_levels[mini(level - 1, power_levels.size() - 1)])
	data.level = level
	return data

func buy_weapon(id):
	var catalog = weapon_catalog()
	if not catalog.has(id) or owned_weapons.get(id, false):
		return false
	var price = int(catalog[id].price)
	if coins < price:
		return false
	coins -= price
	owned_weapons[id] = true
	for i in range(loadout.size()):
		if loadout[i] == "":
			loadout[i] = id
			break
	save_game()
	return true

func upgrade_cost(id):
	var catalog = weapon_catalog()
	if not catalog.has(id):
		return 0
	var level = int(weapon_levels.get(id, 1))
	var costs = catalog[id].get("upgrade_costs", [])
	if level >= 5 or level - 1 >= costs.size():
		return 0
	return int(costs[level - 1])

func upgrade_weapon(id):
	if not owned_weapons.get(id, false):
		return false
	var level = int(weapon_levels.get(id, 1))
	if level >= 5:
		return false
	var cost = upgrade_cost(id)
	if cost <= 0 or coins < cost:
		return false
	coins -= cost
	weapon_levels[id] = level + 1
	save_game()
	return true

func buy_armor():
	if armor_owned or coins < ARMOR_PRICE:
		return false
	coins -= ARMOR_PRICE
	armor_owned = true
	save_game()
	return true

func equip_weapon(id, slot):
	if slot < 0 or slot >= 4:
		return
	if id != "" and not owned_weapons.get(id, false):
		return
	for i in range(loadout.size()):
		if loadout[i] == id and id != "":
			loadout[i] = ""
	loadout[slot] = id
	save_game()

func add_coins(amount):
	coins += max(0, int(amount))
	save_game()

func set_target_fps(value):
	var requested = int(value)
	if not ALLOWED_FPS.has(requested):
		requested = 60
	target_fps = requested
	apply_runtime_settings()
	save_game()

func apply_runtime_settings():
	Engine.max_fps = target_fps

func save_game():
	var data = {
		"coins": coins,
		"owned_weapons": owned_weapons,
		"weapon_levels": weapon_levels,
		"loadout": loadout,
		"armor_owned": armor_owned,
		"auto_fire": auto_fire,
		"look_sensitivity": look_sensitivity,
		"target_fps": target_fps
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		save_game()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", coins))
	owned_weapons = parsed.get("owned_weapons", owned_weapons)
	weapon_levels = parsed.get("weapon_levels", weapon_levels)
	loadout = parsed.get("loadout", loadout)
	armor_owned = bool(parsed.get("armor_owned", armor_owned))
	auto_fire = bool(parsed.get("auto_fire", auto_fire))
	look_sensitivity = clamp(float(parsed.get("look_sensitivity", look_sensitivity)), 0.55, 1.8)
	target_fps = int(parsed.get("target_fps", target_fps))
	if not ALLOWED_FPS.has(target_fps):
		target_fps = 60
	for id in ["rifle", "shotgun"]:
		weapon_levels[id] = clampi(int(weapon_levels.get(id, 1)), 1, 5)
	while loadout.size() < 4:
		loadout.append("")
	if loadout.size() > 4:
		loadout.resize(4)
