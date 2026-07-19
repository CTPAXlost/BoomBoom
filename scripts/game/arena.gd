extends Node3D
class_name BoomArena

signal match_finished

const PlayerScript = preload("res://scripts/game/player.gd")
const BotScript = preload("res://scripts/game/bot.gd")
const HUDScript = preload("res://scripts/ui/mobile_hud.gd")

var blue_score = 0
var red_score = 0
var match_elapsed = 0.0
var score_limit = 25
var match_active = true
var combat_enabled = false
var results_visible = false
var match_coins = 0
var player
var hud
var clouds = []
var blue_spawns = [Vector3(-3.0, 0.1, -9.2), Vector3(-1.0, 0.1, -9.4), Vector3(1.0, 0.1, -9.4), Vector3(3.0, 0.1, -9.2)]
var red_spawns = [Vector3(-3.0, 0.1, 9.2), Vector3(-1.0, 0.1, 9.4), Vector3(1.0, 0.1, 9.4), Vector3(3.0, 0.1, 9.2)]

func _ready():
	randomize()
	_apply_graphics_quality()
	_build_environment()
	hud = HUDScript.new()
	add_child(hud)
	hud.continue_pressed.connect(_on_continue_pressed)
	_spawn_teams()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_start_countdown()

func _apply_graphics_quality():
	var viewport = get_viewport()
	if SaveData.graphics_quality == "low":
		viewport.msaa_3d = Viewport.MSAA_DISABLED
	elif SaveData.graphics_quality == "high":
		viewport.msaa_3d = Viewport.MSAA_4X
	else:
		viewport.msaa_3d = Viewport.MSAA_2X

func _start_countdown():
	combat_enabled = false
	hud.set_combat_controls_enabled(false)
	for number in [5, 4, 3, 2, 1]:
		if not match_active:
			return
		hud.show_countdown(str(number))
		await get_tree().create_timer(1.0).timeout
	if not match_active:
		return
	combat_enabled = true
	hud.show_countdown("В БОЙ!")
	hud.set_combat_controls_enabled(true)
	await get_tree().create_timer(0.7).timeout
	if match_active:
		hud.hide_countdown()
		hud.show_center_message("ПЕРВЫЕ 25 УСТРАНЕНИЙ ПОБЕЖДАЮТ", 1.8)

func _process(delta):
	_update_clouds(delta)
	if not match_active:
		return
	if combat_enabled:
		match_elapsed += delta
	hud.update_match(blue_score, red_score, match_elapsed, match_coins, score_limit)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and match_active:
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
	light.shadow_enabled = SaveData.graphics_quality == "high"
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
	_create_hideouts()
	_create_grass_patches()
	_create_cloud(Vector3(-10, 9.5, -4), 1.1)
	_create_cloud(Vector3(1, 11.0, 2), 1.35)
	if SaveData.graphics_quality != "low":
		_create_cloud(Vector3(11, 9.8, -1), 0.95)
	if SaveData.graphics_quality == "high":
		_create_cloud(Vector3(-3, 12.0, -7), 0.8)
		_create_cloud(Vector3(8, 11.5, 7), 1.05)

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

func _create_hideouts():
	# Two compact wooden shelters and staggered cover create real hiding places.
	for side in [-1.0, 1.0]:
		var x = 6.6 * side
		_create_static_box(Vector3(x, 1.15, -4.6), Vector3(3.4, 2.3, 0.28), Color("79502e"))
		_create_static_box(Vector3(x - 1.55 * side, 1.15, -3.25), Vector3(0.28, 2.3, 2.7), Color("8b5a2b"))
		_create_visual_box(Vector3(x, 2.42, -3.95), Vector3(3.7, 0.22, 3.0), Color("5b3528"), Vector3(0, 0, 8.0 * side))
		_create_static_box(Vector3(x, 0.72, 5.2), Vector3(3.1, 1.44, 0.34), Color("8b5a2b"))
		_create_static_box(Vector3(x + 1.38 * side, 0.72, 4.05), Vector3(0.34, 1.44, 2.6), Color("9a6330"))
	_create_static_box(Vector3(-2.7, 0.8, 0.3), Vector3(0.38, 1.6, 3.8), Color("7b5433"))
	_create_static_box(Vector3(2.7, 0.8, -0.3), Vector3(0.38, 1.6, 3.8), Color("7b5433"))
	_create_static_box(Vector3(0, 0.62, 0), Vector3(2.8, 1.24, 0.36), Color("a46b32"))

func _create_grass_patches():
	var patch_count = 14 if SaveData.graphics_quality == "low" else 36 if SaveData.graphics_quality == "medium" else 72
	for i in range(patch_count):
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
	player.setup_player(self, 0, SaveData.nickname, blue_spawns[0], hud)
	var weapons = SaveData.main_weapon_ids()
	var blue_names = ["Беркут", "Неон", "Шторм"]
	for i in range(3):
		var bot = BotScript.new()
		add_child(bot)
		bot.setup_bot(self, 0, blue_names[i], blue_spawns[i + 1], weapons.pick_random())
	var red_names = ["Кобра", "Титан", "Рейд", "Фантом"]
	for i in range(4):
		var bot = BotScript.new()
		add_child(bot)
		bot.setup_bot(self, 1, red_names[i], red_spawns[i], weapons.pick_random())

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
	victim.deaths += 1
	var valid_killer = is_instance_valid(killer) and killer is Combatant and killer.team != victim.team
	if valid_killer:
		killer.kills += 1
		if killer.team == 0:
			blue_score += 1
		else:
			red_score += 1
	else:
		if victim.team == 0:
			red_score += 1
		else:
			blue_score += 1

	var assistants = []
	if valid_killer:
		assistants = victim.collect_assist_candidates(killer, 10.0)
	for assister in assistants:
		assister.assists += 1
		if assister == player:
			match_coins += 10
	victim.clear_damage_contributors()

	var killer_name = "Окружение"
	if valid_killer:
		killer_name = killer.actor_name
		if killer == player:
			match_coins += 20
	var feed = "%s → %s" % [killer_name, victim.actor_name]
	if not assistants.is_empty():
		var assist_names = []
		for assister in assistants:
			assist_names.append(assister.actor_name)
		feed += "  • ассист: %s" % ", ".join(assist_names)
	hud.show_center_message(feed, 1.25)

	if blue_score >= score_limit or red_score >= score_limit:
		finish_match(false)
	else:
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
	combat_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for actor in get_tree().get_nodes_in_group("combatants"):
		if is_instance_valid(actor):
			actor.velocity = Vector3.ZERO
			actor.set_physics_process(false)
	if is_instance_valid(hud):
		hud.release_controls()

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
	var xp_reward = 0
	var progression = {"leveled_up": false, "level": SaveData.player_level, "xp": SaveData.experience}
	if not aborted:
		xp_reward = 140 + player.kills * 6 + player.assists * 3 + (60 if won else 25 if draw else 10)
		progression = SaveData.add_experience(xp_reward)
	var title = "БОЙ ПРЕРВАН"
	if not aborted:
		title = "НИЧЬЯ" if draw else ("ПОБЕДА!" if won else "ПОРАЖЕНИЕ")
	await get_tree().create_timer(0.45).timeout
	results_visible = true
	hud.show_match_results(
		title,
		blue_score,
		red_score,
		_collect_statistics(),
		reward,
		match_elapsed,
		xp_reward,
		progression
	)

func _collect_statistics():
	var blue_rows = []
	var red_rows = []
	for actor in get_tree().get_nodes_in_group("combatants"):
		if not is_instance_valid(actor):
			continue
		var row = {
			"team": actor.team,
			"name": actor.actor_name,
			"kills": actor.kills,
			"assists": actor.assists,
			"deaths": actor.deaths,
			"player": actor == player
		}
		if actor.team == 0:
			blue_rows.append(row)
		else:
			red_rows.append(row)
	blue_rows.sort_custom(_sort_statistics)
	red_rows.sort_custom(_sort_statistics)
	return blue_rows + red_rows

func _sort_statistics(a, b):
	if int(a["kills"]) == int(b["kills"]):
		if int(a["assists"]) == int(b["assists"]):
			return int(a["deaths"]) < int(b["deaths"])
		return int(a["assists"]) > int(b["assists"])
	return int(a["kills"]) > int(b["kills"])

func _on_continue_pressed():
	if not results_visible:
		return
	match_finished.emit()

func throw_grenade(owner, origin, direction):
	if not combat_enabled or not is_instance_valid(owner):
		return
	var grenade = RigidBody3D.new()
	grenade.position = origin
	grenade.collision_layer = 0
	grenade.collision_mask = 1
	grenade.mass = 0.35
	grenade.gravity_scale = 1.15
	grenade.continuous_cd = true
	var shape_node = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.13
	shape_node.shape = shape
	grenade.add_child(shape_node)
	var mesh_instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.26
	mesh_instance.mesh = mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("354538")
	material.metallic = 0.55
	material.roughness = 0.42
	mesh_instance.material_override = material
	grenade.add_child(mesh_instance)
	add_child(grenade)
	grenade.linear_velocity = direction.normalized() * 13.0 + Vector3.UP * 4.8
	grenade.angular_velocity = Vector3(7.0, 10.0, 4.0)
	await get_tree().create_timer(1.15).timeout
	if is_instance_valid(grenade):
		if match_active:
			_explode_grenade(owner, grenade.global_position)
		grenade.queue_free()

func _explode_grenade(owner, position):
	var radius = 4.5
	for actor in get_tree().get_nodes_in_group("combatants"):
		if not is_instance_valid(actor) or not actor.alive or actor.team == owner.team:
			continue
		if actor.global_position.distance_to(position) <= radius and _blast_has_line(position, actor):
			actor.take_damage(SaveData.GRENADE_DAMAGE, owner)
	var blast = MeshInstance3D.new()
	var blast_mesh = SphereMesh.new()
	blast_mesh.radius = 0.45
	blast_mesh.height = 0.9
	blast.mesh = blast_mesh
	blast.position = position
	var blast_mat = StandardMaterial3D.new()
	blast_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blast_mat.albedo_color = Color("ffb000")
	blast_mat.emission_enabled = true
	blast_mat.emission = Color("ff5a00")
	blast.material_override = blast_mat
	add_child(blast)
	var light = OmniLight3D.new()
	light.light_color = Color("ff8a24")
	light.light_energy = 5.0
	light.omni_range = 7.0
	light.shadow_enabled = false
	light.position = position + Vector3.UP * 0.4
	add_child(light)
	var tween = create_tween()
	tween.tween_property(blast, "scale", Vector3.ONE * 7.0, 0.2)
	await get_tree().create_timer(0.22).timeout
	if is_instance_valid(blast):
		blast.queue_free()
	if is_instance_valid(light):
		light.queue_free()

func _blast_has_line(origin, actor):
	var target_point = actor.global_position + Vector3.UP
	var query = PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.15, target_point)
	query.collision_mask = 3
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == actor

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
