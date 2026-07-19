extends Node

const SAVE_PATH = "user://boom_arena_save.json"
const ALLOWED_FPS = [30, 60, 120]
const GRAPHICS_QUALITIES = ["low", "medium", "high"]
const MAP_IDS = ["farm", "saloon"]
const MAIN_WEAPONS = [
	"rifle",
	"rifle_vortex",
	"rifle_bastion",
	"rifle_phoenix",
	"shotgun",
	"machinegun",
	"sniper"
]
const MAX_PLAYER_LEVEL = 5
const LEVEL_XP = [0, 250, 700, 1400, 2400]
const MEDKIT_PRICE = 500
const GRENADE_PRICE = 300
const MEDKIT_HEAL = 10
const MEDKIT_PER_LIFE = 10
const GRENADE_PER_LIFE = 2
const GRENADE_DAMAGE = 100.0
const HELMET_PRICE = 2200
const HELMET_UNLOCK_LEVEL = 3
const ARMOR_CAPACITIES = [0, 100, 200, 300, 400, 500]
const ARMOR_COSTS = [500, 1000, 1600, 2400, 3500]
const ARMOR_UNLOCK_LEVELS = [1, 2, 2, 3, 4]

var coins = 800
var owned_weapons = {
	"rifle": true,
	"rifle_vortex": false,
	"rifle_bastion": false,
	"rifle_phoenix": false,
	"shotgun": false,
	"machinegun": false,
	"sniper": false
}
var weapon_levels = {
	"rifle": 1,
	"rifle_vortex": 1,
	"rifle_bastion": 1,
	"rifle_phoenix": 1,
	"shotgun": 1,
	"machinegun": 1,
	"sniper": 1
}
var loadout = ["rifle", "", "", ""]
var armor_level = 0
var helmet_owned = false
var auto_fire = true
var aim_assist = true
var look_sensitivity = 1.0
var target_fps = 60
var graphics_quality = "medium"
var show_fps = true
var selected_loadout_slot = 0
var nickname = "Игрок"
var player_level = 1
var experience = 0
var medkits = 30
var grenades = 30
var selected_map = "farm"

func _ready():
	load_game()
	apply_runtime_settings()

func main_weapon_ids():
	return MAIN_WEAPONS.duplicate()

func automatic_weapon_ids():
	return ["rifle", "rifle_vortex", "rifle_bastion", "rifle_phoenix"]

func map_catalog():
	return {
		"farm": {
			"name": "Старая ферма",
			"mode": "Командный бой",
			"description": "Первой устранить 25 противников. Средняя компактная карта с сараями и укрытиями."
		},
		"saloon": {
			"name": "Салун",
			"mode": "Контроль зоны",
			"description": "Захватывай точку 5 секунд и набери 1000 командных очков."
		}
	}

func weapon_catalog():
	return {
		"rifle": {
			"name": "AR-4 Новобранец",
			"type": "Автомат",
			"price": 0,
			"unlock_level": 1,
			"damage_levels": [12.0, 15.0, 19.0, 24.0, 30.0],
			"power_levels": [20, 28, 38, 50, 65],
			"upgrade_costs": [300, 500, 900, 1500],
			"headshot_multiplier": 1.8,
			"fire_rate": 0.12,
			"magazine": 30,
			"reserve": 120,
			"range": 20.0,
			"spread": 0.014,
			"aim_spread_multiplier": 0.42,
			"pellets": 1,
			"reload_time": 2.0,
			"aim_fov": 59.0,
			"recoil_pitch": 0.0062,
			"recoil_yaw": 0.0028,
			"recoil_visual": 0.33,
			"recoil_recovery": 6.2,
			"sound": "res://assets/audio/rifle.wav",
			"color": Color("23e6ff")
		},
		"rifle_vortex": {
			"name": "VX-7 Вихрь",
			"type": "Автомат",
			"price": 1600,
			"unlock_level": 2,
			"damage_levels": [13.0, 16.0, 20.0, 24.0, 29.0],
			"power_levels": [32, 40, 50, 61, 74],
			"upgrade_costs": [450, 750, 1200, 1850],
			"headshot_multiplier": 1.75,
			"fire_rate": 0.082,
			"magazine": 36,
			"reserve": 144,
			"range": 22.0,
			"spread": 0.018,
			"aim_spread_multiplier": 0.45,
			"pellets": 1,
			"reload_time": 2.0,
			"aim_fov": 58.0,
			"recoil_pitch": 0.0068,
			"recoil_yaw": 0.0042,
			"recoil_visual": 0.38,
			"recoil_recovery": 5.6,
			"sound": "res://assets/audio/rifle_fast.wav",
			"color": Color("58f29a")
		},
		"rifle_bastion": {
			"name": "BR-9 Бастион",
			"type": "Автомат",
			"price": 3200,
			"unlock_level": 3,
			"damage_levels": [21.0, 25.0, 30.0, 36.0, 43.0],
			"power_levels": [48, 58, 70, 84, 100],
			"upgrade_costs": [650, 1050, 1650, 2500],
			"headshot_multiplier": 1.85,
			"fire_rate": 0.155,
			"magazine": 28,
			"reserve": 112,
			"range": 25.0,
			"spread": 0.012,
			"aim_spread_multiplier": 0.38,
			"pellets": 1,
			"reload_time": 2.0,
			"aim_fov": 56.0,
			"recoil_pitch": 0.0094,
			"recoil_yaw": 0.0035,
			"recoil_visual": 0.48,
			"recoil_recovery": 5.0,
			"sound": "res://assets/audio/rifle_heavy.wav",
			"color": Color("ff8d4d")
		},
		"rifle_phoenix": {
			"name": "PX-12 Феникс",
			"type": "Автомат",
			"price": 5200,
			"unlock_level": 4,
			"damage_levels": [19.0, 23.0, 28.0, 34.0, 41.0],
			"power_levels": [62, 74, 88, 104, 123],
			"upgrade_costs": [850, 1350, 2100, 3200],
			"headshot_multiplier": 1.9,
			"fire_rate": 0.095,
			"magazine": 40,
			"reserve": 160,
			"range": 28.0,
			"spread": 0.011,
			"aim_spread_multiplier": 0.34,
			"pellets": 1,
			"reload_time": 2.0,
			"aim_fov": 54.0,
			"recoil_pitch": 0.0072,
			"recoil_yaw": 0.0024,
			"recoil_visual": 0.4,
			"recoil_recovery": 6.5,
			"sound": "res://assets/audio/rifle_elite.wav",
			"color": Color("ff4e9a")
		},
		"shotgun": {
			"name": "SG-12 Гром",
			"type": "Дробовик",
			"price": 500,
			"unlock_level": 1,
			"damage_levels": [14.0, 15.5, 17.0, 19.0, 21.0],
			"power_levels": [48, 55, 63, 73, 85],
			"upgrade_costs": [400, 650, 1000, 1600],
			"headshot_multiplier": 1.35,
			"fire_rate": 0.78,
			"magazine": 6,
			"reserve": 30,
			"range": 10.0,
			"spread": 0.082,
			"aim_spread_multiplier": 0.72,
			"pellets": 8,
			"reload_time": 4.0,
			"aim_fov": 67.0,
			"recoil_pitch": 0.021,
			"recoil_yaw": 0.008,
			"recoil_visual": 0.82,
			"recoil_recovery": 4.0,
			"sound": "res://assets/audio/shotgun.wav",
			"color": Color("ffca3a")
		},
		"machinegun": {
			"name": "MG-60 Бизон",
			"type": "Пулемёт",
			"price": 1200,
			"unlock_level": 1,
			"damage_levels": [10.0, 12.0, 14.0, 17.0, 20.0],
			"power_levels": [30, 37, 45, 56, 70],
			"upgrade_costs": [450, 700, 1100, 1700],
			"headshot_multiplier": 1.6,
			"fire_rate": 0.075,
			"magazine": 60,
			"reserve": 180,
			"range": 35.0,
			"spread": 0.026,
			"aim_spread_multiplier": 0.5,
			"pellets": 1,
			"reload_time": 5.0,
			"aim_fov": 56.0,
			"recoil_pitch": 0.0082,
			"recoil_yaw": 0.0055,
			"recoil_visual": 0.45,
			"recoil_recovery": 3.8,
			"sound": "res://assets/audio/machinegun.wav",
			"color": Color("b48cff")
		},
		"sniper": {
			"name": "SR-70 Егерь",
			"type": "Снайперская винтовка",
			"price": 2500,
			"unlock_level": 2,
			"damage_levels": [200.0, 215.0, 230.0, 250.0, 280.0],
			"power_levels": [90, 96, 102, 110, 120],
			"upgrade_costs": [700, 1050, 1550, 2300],
			"headshot_multiplier": 1.2,
			"fire_rate": 1.25,
			"magazine": 5,
			"reserve": 20,
			"range": 70.0,
			"spread": 0.0045,
			"aim_spread_multiplier": 0.08,
			"pellets": 1,
			"reload_time": 3.0,
			"aim_fov": 28.0,
			"recoil_pitch": 0.03,
			"recoil_yaw": 0.007,
			"recoil_visual": 1.0,
			"recoil_recovery": 3.0,
			"sound": "res://assets/audio/sniper.wav",
			"color": Color("9cff57")
		},
		"pistol": {
			"name": "P-9 Резерв",
			"type": "Пистолет",
			"price": 0,
			"unlock_level": 1,
			"damage_levels": [18.0],
			"power_levels": [26],
			"upgrade_costs": [],
			"headshot_multiplier": 1.55,
			"fire_rate": 0.28,
			"magazine": 12,
			"reserve": 48,
			"range": 15.0,
			"spread": 0.02,
			"aim_spread_multiplier": 0.5,
			"pellets": 1,
			"reload_time": 1.5,
			"aim_fov": 62.0,
			"recoil_pitch": 0.009,
			"recoil_yaw": 0.0035,
			"recoil_visual": 0.38,
			"recoil_recovery": 5.6,
			"sound": "res://assets/audio/pistol.wav",
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

func is_weapon_unlocked(id):
	var catalog = weapon_catalog()
	return catalog.has(id) and player_level >= int(catalog[id].get("unlock_level", 1))

func buy_weapon(id):
	var catalog = weapon_catalog()
	if not catalog.has(id) or owned_weapons.get(id, false) or not is_weapon_unlocked(id):
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

func armor_capacity():
	return int(ARMOR_CAPACITIES[clampi(armor_level, 0, ARMOR_CAPACITIES.size() - 1)])

func armor_next_cost():
	if armor_level >= ARMOR_COSTS.size():
		return 0
	return int(ARMOR_COSTS[armor_level])

func armor_next_unlock_level():
	if armor_level >= ARMOR_UNLOCK_LEVELS.size():
		return MAX_PLAYER_LEVEL
	return int(ARMOR_UNLOCK_LEVELS[armor_level])

func can_upgrade_armor():
	return armor_level < ARMOR_COSTS.size() and player_level >= armor_next_unlock_level()

func buy_or_upgrade_armor():
	if not can_upgrade_armor():
		return false
	var price = armor_next_cost()
	if price <= 0 or coins < price:
		return false
	coins -= price
	armor_level += 1
	save_game()
	return true

func can_buy_helmet():
	return not helmet_owned and player_level >= HELMET_UNLOCK_LEVEL

func buy_helmet():
	if not can_buy_helmet() or coins < HELMET_PRICE:
		return false
	coins -= HELMET_PRICE
	helmet_owned = true
	save_game()
	return true

func buy_consumable(id, amount = 1):
	var count = maxi(1, int(amount))
	var unit_price = MEDKIT_PRICE if id == "medkit" else GRENADE_PRICE if id == "grenade" else 0
	if unit_price <= 0 or coins < unit_price * count:
		return false
	coins -= unit_price * count
	if id == "medkit":
		medkits += count
	else:
		grenades += count
	save_game()
	return true

func consume_medkit():
	if medkits <= 0:
		return false
	medkits -= 1
	save_game()
	return true

func consume_grenade():
	if grenades <= 0:
		return false
	grenades -= 1
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

func set_coins(amount):
	coins = clampi(int(amount), 0, 999999999)
	save_game()

func level_for_experience(value):
	var level = 1
	for i in range(LEVEL_XP.size()):
		if int(value) >= int(LEVEL_XP[i]):
			level = i + 1
	return clampi(level, 1, MAX_PLAYER_LEVEL)

func xp_for_next_level():
	if player_level >= MAX_PLAYER_LEVEL:
		return 0
	return int(LEVEL_XP[player_level])

func xp_progress_text():
	if player_level >= MAX_PLAYER_LEVEL:
		return "МАКС. УРОВЕНЬ"
	return "%d / %d XP" % [experience, xp_for_next_level()]

func add_experience(amount):
	var previous_level = player_level
	experience += max(0, int(amount))
	player_level = level_for_experience(experience)
	var leveled_up = player_level > previous_level
	save_game()
	return {
		"leveled_up": leveled_up,
		"level": player_level,
		"previous_level": previous_level,
		"xp": experience
	}

func player_max_health():
	return 200 if player_level >= 2 else 100

func set_nickname(value):
	var clean = str(value).strip_edges().replace("\n", " ").replace("\r", " ")
	if clean.length() > 18:
		clean = clean.left(18)
	if clean.is_empty():
		clean = "Игрок"
	nickname = clean
	save_game()

func set_selected_map(value):
	var requested = str(value)
	if not MAP_IDS.has(requested):
		requested = "farm"
	selected_map = requested
	save_game()

func set_target_fps(value):
	var requested = int(value)
	if not ALLOWED_FPS.has(requested):
		requested = 60
	target_fps = requested
	apply_runtime_settings()
	save_game()

func set_graphics_quality(value):
	var requested = str(value).to_lower()
	if not GRAPHICS_QUALITIES.has(requested):
		requested = "medium"
	graphics_quality = requested
	save_game()

func apply_runtime_settings():
	Engine.max_fps = target_fps

func save_game():
	var data = {
		"coins": coins,
		"owned_weapons": owned_weapons,
		"weapon_levels": weapon_levels,
		"loadout": loadout,
		"armor_level": armor_level,
		"helmet_owned": helmet_owned,
		"auto_fire": auto_fire,
		"aim_assist": aim_assist,
		"look_sensitivity": look_sensitivity,
		"target_fps": target_fps,
		"graphics_quality": graphics_quality,
		"show_fps": show_fps,
		"nickname": nickname,
		"player_level": player_level,
		"experience": experience,
		"medkits": medkits,
		"grenades": grenades,
		"selected_map": selected_map
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game():
	var parsed = {}
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var loaded = JSON.parse_string(file.get_as_text())
			if typeof(loaded) == TYPE_DICTIONARY:
				parsed = loaded
				coins = int(parsed.get("coins", coins))
				owned_weapons = parsed.get("owned_weapons", owned_weapons)
				weapon_levels = parsed.get("weapon_levels", weapon_levels)
				loadout = parsed.get("loadout", loadout)
				auto_fire = bool(parsed.get("auto_fire", auto_fire))
				aim_assist = bool(parsed.get("aim_assist", aim_assist))
				look_sensitivity = clamp(float(parsed.get("look_sensitivity", look_sensitivity)), 0.55, 1.8)
				target_fps = int(parsed.get("target_fps", target_fps))
				graphics_quality = str(parsed.get("graphics_quality", graphics_quality))
				show_fps = bool(parsed.get("show_fps", show_fps))
				nickname = str(parsed.get("nickname", nickname))
				player_level = int(parsed.get("player_level", player_level))
				experience = int(parsed.get("experience", experience))
				medkits = int(parsed.get("medkits", medkits))
				grenades = int(parsed.get("grenades", grenades))
				helmet_owned = bool(parsed.get("helmet_owned", helmet_owned))
				selected_map = str(parsed.get("selected_map", selected_map))
				if parsed.has("armor_level"):
					armor_level = int(parsed.get("armor_level", armor_level))
				elif bool(parsed.get("armor_owned", false)):
					armor_level = 1
	_migrate_save()
	save_game()

func _migrate_save():
	var catalog = weapon_catalog()
	for id in MAIN_WEAPONS:
		if not owned_weapons.has(id):
			owned_weapons[id] = id == "rifle"
		if not weapon_levels.has(id):
			weapon_levels[id] = 1
		weapon_levels[id] = clampi(int(weapon_levels.get(id, 1)), 1, 5)
	while loadout.size() < 4:
		loadout.append("")
	if loadout.size() > 4:
		loadout.resize(4)
	for i in range(loadout.size()):
		var id = str(loadout[i])
		if id != "" and (not catalog.has(id) or not owned_weapons.get(id, false)):
			loadout[i] = ""
	if not loadout.has("rifle") and owned_weapons.get("rifle", true):
		var has_weapon = false
		for id in loadout:
			if id != "":
				has_weapon = true
		if not has_weapon:
			loadout[0] = "rifle"
	if not ALLOWED_FPS.has(target_fps):
		target_fps = 60
	if not GRAPHICS_QUALITIES.has(graphics_quality):
		graphics_quality = "medium"
	if not MAP_IDS.has(selected_map):
		selected_map = "farm"
	armor_level = clampi(armor_level, 0, ARMOR_CAPACITIES.size() - 1)
	experience = maxi(0, experience)
	player_level = level_for_experience(experience)
	medkits = maxi(0, medkits)
	grenades = maxi(0, grenades)
	var clean_name = str(nickname).strip_edges().replace("\n", " ").replace("\r", " ")
	if clean_name.length() > 18:
		clean_name = clean_name.left(18)
	if clean_name.is_empty():
		clean_name = "Игрок"
	nickname = clean_name
