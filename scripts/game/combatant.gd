extends CharacterBody3D
class_name Combatant

var game
var team = 0
var health = 100.0
var max_health = 100.0
var armor = 0.0
var max_armor = 0.0
var alive = true
var last_attacker
var actor_name = "Боец"
var spawn_position = Vector3.ZERO
var last_armor_damage = 0.0
var last_health_damage = 0.0
var kills = 0
var assists = 0
var deaths = 0
var score_points = 0
var life_streak = 0
var best_streak = 0
var captures = 0
var zone_seconds = 0.0
var damage_contributors = {}
var last_damage_info = {"method": "environment", "headshot": false}
var headshot_damage_multiplier = 1.0

func setup(p_game, p_team, p_name, p_spawn):
	game = p_game
	team = p_team
	actor_name = p_name
	spawn_position = p_spawn
	global_position = p_spawn
	collision_layer = 2
	collision_mask = 3
	add_to_group("combatants")
	add_to_group("team_%d" % team)

func set_armor_capacity(value):
	max_armor = max(0.0, float(value))
	armor = max_armor

func take_damage(amount, attacker = null, hit_info = {}):
	if not alive:
		return
	last_attacker = attacker
	var info = {
		"method": str(hit_info.get("method", "weapon")),
		"headshot": bool(hit_info.get("headshot", false))
	}
	var remaining = max(0.0, float(amount))
	if bool(info.headshot):
		remaining *= clamp(headshot_damage_multiplier, 0.05, 1.0)
	last_damage_info = info
	last_armor_damage = 0.0
	last_health_damage = 0.0
	if armor > 0.0 and remaining > 0.0:
		last_armor_damage = min(armor, remaining)
		armor = max(0.0, armor - last_armor_damage)
		remaining -= last_armor_damage
	if remaining > 0.0:
		last_health_damage = min(health, remaining)
		health = max(0.0, health - last_health_damage)
	var actual_damage = last_armor_damage + last_health_damage
	if actual_damage > 0.0:
		_register_damage_contributor(attacker, actual_damage)
	on_health_changed()
	if health <= 0.0:
		die(attacker)

func _register_damage_contributor(attacker, amount):
	if not is_instance_valid(attacker) or attacker == self:
		return
	if not (attacker is Combatant) or attacker.team == team:
		return
	var key = attacker.get_instance_id()
	var entry = damage_contributors.get(key, {})
	entry["actor"] = attacker
	entry["damage"] = float(entry.get("damage", 0.0)) + float(amount)
	entry["time"] = Time.get_ticks_msec() * 0.001
	damage_contributors[key] = entry

func collect_assist_candidates(killer, window_seconds = 10.0):
	var result = []
	var now = Time.get_ticks_msec() * 0.001
	for key in damage_contributors:
		var entry = damage_contributors[key]
		var contributor = entry.get("actor")
		if not is_instance_valid(contributor) or contributor == killer:
			continue
		if not (contributor is Combatant):
			continue
		if is_instance_valid(killer) and contributor.team != killer.team:
			continue
		if now - float(entry.get("time", 0.0)) > float(window_seconds):
			continue
		if float(entry.get("damage", 0.0)) < 1.0:
			continue
		result.append(contributor)
	return result

func clear_damage_contributors():
	damage_contributors.clear()

func die(attacker):
	if not alive:
		return
	alive = false
	velocity = Vector3.ZERO
	visible = false
	collision_layer = 0
	collision_mask = 0
	game.register_kill(attacker, self, last_damage_info)

func respawn_at(point):
	spawn_position = point
	global_position = point
	health = max_health
	armor = max_armor
	last_armor_damage = 0.0
	last_health_damage = 0.0
	last_damage_info = {"method": "environment", "headshot": false}
	clear_damage_contributors()
	life_streak = 0
	alive = true
	visible = true
	collision_layer = 2
	collision_mask = 3
	velocity = Vector3.ZERO
	on_respawned()

func on_health_changed():
	pass

func on_respawned():
	pass
