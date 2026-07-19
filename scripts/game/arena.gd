extends Node3D
class_name BoomArena

signal match_finished(summary)

const PlayerScript = preload("res://scripts/game/player.gd")
const BotScript = preload("res://scripts/game/bot.gd")
const HUDScript = preload("res://scripts/ui/mobile_hud.gd")

var blue_score = 0
var red_score = 0
var time_left = 180.0
var score_limit = 20
var match_active = true
var match_coins = 0
var player
var hud
var blue_spawns = [Vector3(-14, 0.1, -13), Vector3(-10, 0.1, -13), Vector3(-14, 0.1, -9), Vector3(-10, 0.1, -9)]
var red_spawns = [Vector3(14, 0.1, 13), Vector3(10, 0.1, 13), Vector3(14, 0.1, 9), Vector3(10, 0.1, 9)]

func _ready():
	randomize()
	_build_environment()
	hud = HUDScript.new()
	add_child(hud)
	_spawn_teams()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_center_message("БОЙ НАЧАЛСЯ")

func _process(delta):
	if not match_active:
		return
	time_left = max(0.0, time_left - delta)
	hud.update_match(blue_score, red_score, time_left, match_coins)
	if time_left <= 0.0 or blue_score >= score_limit or red_score >= score_limit:
		finish_match()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		finish_match(true)

func _build_environment():
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("7db4d8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7ebf7")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -34, 0)
	light.light_energy = 1.05
	light.shadow_enabled = false
	add_child(light)
	_create_static_box(Vector3(0, -0.3, 0), Vector3(36, 0.6, 36), Color("526b52"))
	_create_static_box(Vector3(0, 2.0, -18), Vector3(36, 4, 0.7), Color("31485c"))
	_create_static_box(Vector3(0, 2.0, 18), Vector3(36, 4, 0.7), Color("31485c"))
	_create_static_box(Vector3(-18, 2.0, 0), Vector3(0.7, 4, 36), Color("31485c"))
	_create_static_box(Vector3(18, 2.0, 0), Vector3(0.7, 4, 36), Color("31485c"))
	var covers = [
		[Vector3(-8, 1.2, -5), Vector3(4.5, 2.4, 1.4)],
		[Vector3(8, 1.2, 5), Vector3(4.5, 2.4, 1.4)],
		[Vector3(-5, 1.2, 8), Vector3(1.4, 2.4, 4.5)],
		[Vector3(5, 1.2, -8), Vector3(1.4, 2.4, 4.5)],
		[Vector3(0, 1.0, 0), Vector3(3.0, 2.0, 3.0)],
		[Vector3(-12, 0.8, 2), Vector3(2.2, 1.6, 2.2)],
		[Vector3(12, 0.8, -2), Vector3(2.2, 1.6, 2.2)]
	]
	for item in covers:
		_create_static_box(item[0], item[1], Color("b7793f"))
	_create_team_pad(Vector3(-12, 0.02, -11), Color("2d9cff"))
	_create_team_pad(Vector3(12, 0.02, 11), Color("ff3d68"))

func _create_static_box(pos, box_size, color):
	var body = StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	add_child(body)

func _create_team_pad(pos, color):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.position = pos
	var mesh = CylinderMesh.new()
	mesh.top_radius = 3.8
	mesh.bottom_radius = 3.8
	mesh.height = 0.08
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.65)
	mat.emission_enabled = true
	mat.emission = Color(color, 0.35)
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _spawn_teams():
	player = PlayerScript.new()
	add_child(player)
	player.setup_player(self, 0, "Игрок", blue_spawns[0], hud)
	var blue_names = ["Беркут", "Неон", "Шторм"]
	for i in range(3):
		var bot = BotScript.new()
		add_child(bot)
		bot.setup_bot(self, 0, blue_names[i], blue_spawns[i + 1], "rifle" if i < 2 else "shotgun")
	var red_names = ["Кобра", "Титан", "Рейд", "Фантом"]
	for i in range(4):
		var bot = BotScript.new()
		add_child(bot)
		bot.setup_bot(self, 1, red_names[i], red_spawns[i], "shotgun" if i == 1 else "rifle")

func find_nearest_enemy(actor):
	var best
	var best_distance = INF
	for candidate in get_tree().get_nodes_in_group("combatants"):
		if candidate == actor or not candidate.alive or candidate.team == actor.team:
			continue
		var distance = actor.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func register_kill(killer, victim):
	if not match_active:
		return
	if victim.team == 0:
		red_score += 1
	else:
		blue_score += 1
	var killer_name = "Окружение"
	if is_instance_valid(killer):
		killer_name = killer.actor_name
		if killer == player:
			match_coins += 20
	hud.show_center_message("%s → %s" % [killer_name, victim.actor_name])
	_respawn_later(victim)

func _respawn_later(actor):
	await get_tree().create_timer(2.6).timeout
	if not match_active or not is_instance_valid(actor):
		return
	var spawns = blue_spawns if actor.team == 0 else red_spawns
	actor.respawn_at(spawns[randi() % spawns.size()])

func finish_match(aborted = false):
	if not match_active:
		return
	match_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var won = blue_score > red_score
	var draw = blue_score == red_score
	var reward = match_coins
	if not aborted:
		if won:
			reward += 150
		elif draw:
			reward += 100
		else:
			reward += 60
	SaveData.add_coins(reward)
	var title = "БОЙ ПРЕРВАН"
	if not aborted:
		title = "НИЧЬЯ" if draw else ("ПОБЕДА!" if won else "ПОРАЖЕНИЕ")
	var summary = "%s\nСчёт: %d — %d\nЗаработано монет: %d" % [title, blue_score, red_score, reward]
	await get_tree().create_timer(0.25).timeout
	match_finished.emit(summary)

func spawn_tracer(start, finish, color, hit_enemy = false):
	var direction = finish - start
	var length = direction.length()
	if length < 0.03:
		return
	var up = direction / length
	var side = up.cross(Vector3.FORWARD)
	if side.length_squared() < 0.001:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var forward = side.cross(up).normalized()

	var tracer = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.018
	mesh.height = length
	mesh.radial_segments = 6
	mesh.rings = 1
	tracer.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color.lerp(Color.WHITE, 0.45)
	mat.emission_enabled = true
	mat.emission = color.lerp(Color.WHITE, 0.35)
	tracer.material_override = mat
	tracer.global_transform = Transform3D(Basis(side, up, forward), (start + finish) * 0.5)
	add_child(tracer)

	if hit_enemy:
		var impact = MeshInstance3D.new()
		var impact_mesh = SphereMesh.new()
		impact_mesh.radius = 0.055
		impact_mesh.height = 0.11
		impact.mesh = impact_mesh
		impact.position = finish
		var impact_mat = StandardMaterial3D.new()
		impact_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		impact_mat.albedo_color = Color("ffca3a")
		impact_mat.emission_enabled = true
		impact_mat.emission = Color("ff7b00")
		impact.material_override = impact_mat
		add_child(impact)
		_remove_effect_later(impact, 0.09)
	_remove_effect_later(tracer, 0.06)

func _remove_effect_later(effect, delay):
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(effect):
		effect.queue_free()
