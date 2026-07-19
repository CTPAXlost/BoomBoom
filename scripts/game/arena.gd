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
var clouds = []
var blue_spawns = [Vector3(-3.0, 0.1, -9.2), Vector3(-1.0, 0.1, -9.4), Vector3(1.0, 0.1, -9.4), Vector3(3.0, 0.1, -9.2)]
var red_spawns = [Vector3(-3.0, 0.1, 9.2), Vector3(-1.0, 0.1, 9.4), Vector3(1.0, 0.1, 9.4), Vector3(3.0, 0.1, 9.2)]

func _ready():
	randomize()
	_build_environment()
	hud = HUDScript.new()
	add_child(hud)
	_spawn_teams()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.show_center_message("СТАРАЯ ФЕРМА")

func _process(delta):
	_update_clouds(delta)
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
	env.background_color = Color("82c9f2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e4f5ff")
	env.ambient_light_energy = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -28, 0)
	light.light_color = Color("fff5d6")
	light.light_energy = 1.18
	light.shadow_enabled = false
	add_child(light)

	_create_static_box(Vector3(0, -0.3, 0), Vector3(30, 0.6, 26), Color("4d9a45"))
	_create_static_box(Vector3(0, 2.0, -13.2), Vector3(30, 4, 0.5), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(0, 2.0, 13.2), Vector3(30, 4, 0.5), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(-15.2, 2.0, 0), Vector3(0.5, 4, 26), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(15.2, 2.0, 0), Vector3(0.5, 4, 26), Color.TRANSPARENT, Vector3.ZERO, false)

	_create_barn(Vector3(0, 0, -10.8), 1, Color("2d9cff"))
	_create_barn(Vector3(0, 0, 10.8), -1, Color("ff3d68"))
	_create_team_pad(Vector3(0, 0.02, -8.9), Color("2d9cff"))
	_create_team_pad(Vector3(0, 0.02, 8.9), Color("ff3d68"))

	_create_hay_bale(Vector3(-3.6, 0.72, -1.0), 90.0)
	_create_hay_bale(Vector3(3.6, 0.72, 1.0), 90.0)
	_create_hay_bale(Vector3(0.0, 0.72, 3.8), 0.0)
	_create_static_box(Vector3(-0.9, 0.75, -2.8), Vector3(1.5, 1.5, 1.5), Color("8b5a2b"))
	_create_static_box(Vector3(0.85, 0.55, -2.8), Vector3(1.15, 1.1, 1.15), Color("a46b32"))
	_create_static_box(Vector3(-8.2, 0.75, 0.0), Vector3(3.5, 1.5, 0.45), Color("9a6330"))
	_create_static_box(Vector3(8.2, 0.75, 0.0), Vector3(3.5, 1.5, 0.45), Color("9a6330"))

	_create_side_fences()
	_create_tree(Vector3(-12.3, 0, -7.0), 1.05)
	_create_tree(Vector3(12.1, 0, 6.8), 1.0)
	_create_tree(Vector3(-12.0, 0, 7.8), 0.9)
	_create_tree(Vector3(12.4, 0, -7.7), 0.95)
	_create_grass_patches()
	_create_cloud(Vector3(-10, 9.5, -4), 1.1)
	_create_cloud(Vector3(1, 11.0, 2), 1.35)
	_create_cloud(Vector3(11, 9.8, -1), 0.95)

func _create_barn(base, opening_sign, team_color):
	var wall_color = Color("a94f3d")
	var trim_color = Color("f3e3c3")
	var roof_color = Color("5b3528")
	var back_z = base.z - 1.45 * opening_sign
	var front_z = base.z + 1.45 * opening_sign
	_create_static_box(Vector3(base.x, 1.8, back_z), Vector3(8.4, 3.6, 0.35), wall_color)
	_create_static_box(Vector3(base.x - 4.05, 1.7, base.z), Vector3(0.35, 3.4, 3.25), wall_color)
	_create_static_box(Vector3(base.x + 4.05, 1.7, base.z), Vector3(0.35, 3.4, 3.25), wall_color)
	_create_static_box(Vector3(base.x - 2.55, 0.65, front_z), Vector3(2.6, 1.3, 0.28), trim_color)
	_create_static_box(Vector3(base.x + 2.55, 0.65, front_z), Vector3(2.6, 1.3, 0.28), trim_color)
	_create_visual_box(Vector3(base.x - 2.0, 4.0, base.z), Vector3(4.8, 0.36, 3.9), roof_color, Vector3(0, 0, -24))
	_create_visual_box(Vector3(base.x + 2.0, 4.0, base.z), Vector3(4.8, 0.36, 3.9), roof_color, Vector3(0, 0, 24))
	_create_visual_box(Vector3(base.x, 2.95, front_z + 0.03 * opening_sign), Vector3(2.2, 0.22, 0.22), team_color)
	_create_visual_box(Vector3(base.x, 2.45, front_z + 0.04 * opening_sign), Vector3(0.22, 1.15, 0.22), team_color)

func _create_side_fences():
	for z in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		_create_visual_box(Vector3(-14.4, 0.75, z), Vector3(0.18, 1.5, 0.18), Color("79502e"))
		_create_visual_box(Vector3(14.4, 0.75, z), Vector3(0.18, 1.5, 0.18), Color("79502e"))
	for z in [-6.0, -2.0, 2.0, 6.0]:
		_create_visual_box(Vector3(-14.35, 0.65, z), Vector3(0.16, 0.18, 4.0), Color("9a6330"))
		_create_visual_box(Vector3(-14.35, 1.08, z), Vector3(0.16, 0.18, 4.0), Color("9a6330"))
		_create_visual_box(Vector3(14.35, 0.65, z), Vector3(0.16, 0.18, 4.0), Color("9a6330"))
		_create_visual_box(Vector3(14.35, 1.08, z), Vector3(0.16, 0.18, 4.0), Color("9a6330"))

func _create_grass_patches():
	for i in range(34):
		var x = randf_range(-13.5, 13.5)
		var z = randf_range(-11.5, 11.5)
		if abs(z) > 8.2 and abs(x) < 5.0:
			continue
		var height = randf_range(0.08, 0.22)
		_create_visual_box(Vector3(x, height * 0.5, z), Vector3(0.045, height, 0.045), Color("72bd52"), Vector3(randf_range(-8, 8), randf_range(0, 180), randf_range(-8, 8)))

func _create_tree(pos, scale_value):
	_create_static_box(pos + Vector3(0, 1.0 * scale_value, 0), Vector3(0.45, 2.0, 0.45) * scale_value, Color("6d4728"))
	var crown = MeshInstance3D.new()
	crown.position = pos + Vector3(0, 2.55 * scale_value, 0)
	var mesh = SphereMesh.new()
	mesh.radius = 1.25 * scale_value
	mesh.height = 2.5 * scale_value
	crown.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("3f8f3f")
	mat.roughness = 0.95
	crown.material_override = mat
	add_child(crown)

func _create_hay_bale(pos, yaw_degrees):
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_degrees, 90)
	body.collision_layer = 1
	body.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.72
	shape.height = 1.55
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.72
	mesh.bottom_radius = 0.72
	mesh.height = 1.55
	mesh.radial_segments = 18
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("d7ae45")
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	add_child(body)

func _create_cloud(pos, scale_value):
	var cluster = Node3D.new()
	cluster.position = pos
	cluster.scale = Vector3.ONE * scale_value
	for offset in [Vector3(-0.9, 0, 0), Vector3(0, 0.25, 0), Vector3(0.95, 0, 0), Vector3(0.3, -0.12, 0.35)]:
		var puff = MeshInstance3D.new()
		puff.position = offset
		var mesh = SphereMesh.new()
		mesh.radius = 0.9
		mesh.height = 1.25
		puff.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.94)
		mat.roughness = 1.0
		puff.material_override = mat
		cluster.add_child(puff)
	add_child(cluster)
	clouds.append(cluster)

func _update_clouds(delta):
	for cloud in clouds:
		if not is_instance_valid(cloud):
			continue
		cloud.position.x += delta * 0.32
		if cloud.position.x > 18.0:
			cloud.position.x = -18.0

func _create_static_box(pos, box_size, color, rotation_deg = Vector3.ZERO, visible_mesh = true):
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rotation_deg
	body.collision_layer = 1
	body.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	if visible_mesh:
		var mesh_instance = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = box_size
		mesh_instance.mesh = mesh
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.78
		mesh_instance.material_override = mat
		body.add_child(mesh_instance)
	add_child(body)

func _create_visual_box(pos, box_size, color, rotation_deg = Vector3.ZERO):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rotation_deg
	var mesh = BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _create_team_pad(pos, color):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.position = pos
	var mesh = CylinderMesh.new()
	mesh.top_radius = 3.4
	mesh.bottom_radius = 3.4
	mesh.height = 0.07
	mesh_instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.48)
	mat.emission_enabled = true
	mat.emission = Color(color, 0.22)
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
