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

func take_damage(amount, attacker = null):
	if not alive:
		return
	last_attacker = attacker
	var remaining = max(0.0, float(amount))
	last_armor_damage = 0.0
	last_health_damage = 0.0
	if armor > 0.0 and remaining > 0.0:
		last_armor_damage = min(armor, remaining)
		armor = max(0.0, armor - last_armor_damage)
		remaining -= last_armor_damage
	if remaining > 0.0:
		last_health_damage = remaining
		health = max(0.0, health - remaining)
	on_health_changed()
	if health <= 0.0:
		die(attacker)

func die(attacker):
	if not alive:
		return
	alive = false
	velocity = Vector3.ZERO
	visible = false
	collision_layer = 0
	collision_mask = 0
	game.register_kill(attacker, self)

func respawn_at(point):
	spawn_position = point
	global_position = point
	health = max_health
	armor = max_armor
	last_armor_damage = 0.0
	last_health_damage = 0.0
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
