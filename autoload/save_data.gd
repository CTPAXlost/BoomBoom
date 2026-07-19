extends Node

const SAVE_PATH = "user://boom_arena_save.json"

var coins = 800
var owned_weapons = {"rifle": true, "shotgun": false}
var weapon_levels = {"rifle": 1, "shotgun": 1}
var loadout = ["rifle", "", "", ""]
var auto_fire = true
var look_sensitivity = 1.0
var selected_loadout_slot = 0

func _ready():
	load_game()

func weapon_catalog():
	return {
		"rifle": {
			"name": "AR-4 Штурм",
			"type": "Автомат",
			"price": 0,
			"damage": 15.0,
			"fire_rate": 0.105,
			"magazine": 30,
			"reserve": 120,
			"range": 55.0,
			"spread": 0.013,
			"pellets": 1,
			"color": Color("23e6ff")
		},
		"shotgun": {
			"name": "SG-12 Гром",
			"type": "Дробовик",
			"price": 500,
			"damage": 10.0,
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
			"damage": 21.0,
			"fire_rate": 0.28,
			"magazine": 12,
			"reserve": 48,
			"range": 42.0,
			"spread": 0.02,
			"pellets": 1,
			"color": Color("eeeeee")
		}
	}

func get_weapon_stats(id):
	var catalog = weapon_catalog()
	if not catalog.has(id):
		return {}
	var data = catalog[id].duplicate(true)
	var level = int(weapon_levels.get(id, 1))
	if id != "pistol":
		data.damage *= 1.0 + float(level - 1) * 0.09
		data.level = level
	else:
		data.level = 1
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
	var level = int(weapon_levels.get(id, 1))
	return 250 * level

func upgrade_weapon(id):
	if not owned_weapons.get(id, false):
		return false
	var level = int(weapon_levels.get(id, 1))
	if level >= 5:
		return false
	var cost = upgrade_cost(id)
	if coins < cost:
		return false
	coins -= cost
	weapon_levels[id] = level + 1
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

func save_game():
	var data = {
		"coins": coins,
		"owned_weapons": owned_weapons,
		"weapon_levels": weapon_levels,
		"loadout": loadout,
		"auto_fire": auto_fire,
		"look_sensitivity": look_sensitivity
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
	auto_fire = bool(parsed.get("auto_fire", auto_fire))
	look_sensitivity = clamp(float(parsed.get("look_sensitivity", look_sensitivity)), 0.55, 1.8)
	while loadout.size() < 4:
		loadout.append("")
	if loadout.size() > 4:
		loadout.resize(4)
