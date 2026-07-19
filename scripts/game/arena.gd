extends Node3D
class_name BoomArena

signal match_finished

const PlayerScript = preload("res://scripts/game/player.gd")
const BotScript = preload("res://scripts/game/bot.gd")
const HUDScript = preload("res://scripts/ui/mobile_hud.gd")
const GRENADE_SOUND = preload("res://assets/audio/grenade.wav")

var mode_id = "farm"
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
var blue_spawns = []
var red_spawns = []
var first_blood_taken = false
var zone_position = Vector3.ZERO
var zone_radius = 3.2
var zone_owner = -1
var zone_capture_team = -1
var zone_capture_progress = 0.0
var zone_score_accumulator = 0.0
var zone_mesh
var zone_material
var zone_contested = false
var grenade_audio

func _ready():
	randomize()
	mode_id = SaveData.selected_map
	score_limit = 1000 if mode_id == "saloon" else 25
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
	hud.set_precombat_mode(true)
	for number in [5, 4, 3, 2, 1]:
		if not match_active:
			return
		hud.show_countdown("%d\nВЫБЕРИ СТАРТОВОЕ ОРУЖИЕ" % number)
		await get_tree().create_timer(1.0).timeout
	if not match_active:
		return
	combat_enabled = true
	hud.show_countdown("В БОЙ!")
	hud.set_precombat_mode(false)
	hud.set_combat_controls_enabled(true)
	await get_tree().create_timer(0.7).timeout
	if match_active:
		hud.hide_countdown()
		if mode_id == "saloon":
			hud.show_center_message("КОНТРОЛЬ ЗОНЫ • ЦЕЛЬ 1000 ОЧКОВ", 2.0)
		else:
			hud.show_center_message("ПЕРВЫЕ 25 УСТРАНЕНИЙ ПОБЕЖДАЮТ", 1.8)

func _process(delta):
	_update_clouds(delta)
	if not match_active:
		return
	if combat_enabled:
		match_elapsed += delta
		if mode_id == "saloon":
			_update_control_zone(delta)
	hud.update_match(blue_score, red_score, match_elapsed, match_coins, score_limit, mode_id)
	if mode_id == "saloon":
		hud.update_zone(zone_owner, zone_capture_team, zone_capture_progress, zone_contested)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and match_active:
		finish_match(true)

func _build_environment():
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("82c9f2") if mode_id == "farm" else Color("e7a75d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e4f5ff") if mode_id == "farm" else Color("ffe1b5")
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

	grenade_audio = AudioStreamPlayer3D.new()
	grenade_audio.stream = GRENADE_SOUND
	grenade_audio.max_distance = 55.0
	grenade_audio.unit_size = 5.0
	add_child(grenade_audio)

	if mode_id == "saloon":
		_build_saloon()
	else:
		_build_farm()

func _build_farm():
	blue_spawns = [
		Vector3(-4.5, 0.1, -14.4), Vector3(-1.5, 0.1, -14.7),
		Vector3(1.5, 0.1, -14.7), Vector3(4.5, 0.1, -14.4)
	]
	red_spawns = [
		Vector3(-4.5, 0.1, 14.4), Vector3(-1.5, 0.1, 14.7),
		Vector3(1.5, 0.1, 14.7), Vector3(4.5, 0.1, 14.4)
	]
	_create_static_box(Vector3(0, -0.3, 0), Vector3(42, 0.6, 34), Color("4d9a45"))
	_create_boundaries(42, 34)
	_create_barn(Vector3(0, 0, -14.0), 1, Color("2d9cff"))
	_create_barn(Vector3(0, 0, 14.0), -1, Color("ff3d68"))
	_create_team_pad(Vector3(0, 0.02, -12.5), Color("2d9cff"), 4.2)
	_create_team_pad(Vector3(0, 0.02, 12.5), Color("ff3d68"), 4.2)

	for item in [
		[Vector3(-6.8, 0.72, -3.2), 90.0], [Vector3(6.8, 0.72, 3.2), 90.0],
		[Vector3(-1.5, 0.72, 5.4), 0.0], [Vector3(2.2, 0.72, -5.6), 0.0]
	]:
		_create_hay_bale(item[0], item[1])
	_create_farm_lanes()
	_create_tree(Vector3(-18.2, 0, -8.0), 1.05)
	_create_tree(Vector3(18.1, 0, 8.2), 1.0)
	_create_tree(Vector3(-17.0, 0, 10.2), 0.9)
	_create_tree(Vector3(17.4, 0, -10.0), 0.95)
	_create_grass_patches(20.0, 15.0)
	_create_cloud(Vector3(-12, 9.5, -4), 1.1)
	_create_cloud(Vector3(1, 11.0, 2), 1.35)
	if SaveData.graphics_quality != "low":
		_create_cloud(Vector3(13, 9.8, -1), 0.95)

func _create_farm_lanes():
	var wood = Color("8b5a2b")
	# Left and right lanes are separated by staggered cover, reducing 4-on-4 piles.
	for side in [-1.0, 1.0]:
		var x = 10.5 * side
		_create_static_box(Vector3(x, 1.15, -6.2), Vector3(4.2, 2.3, 0.32), wood)
		_create_static_box(Vector3(x - 1.9 * side, 1.15, -4.4), Vector3(0.32, 2.3, 3.7), Color("79502e"))
		_create_visual_box(Vector3(x, 2.45, -5.2), Vector3(4.6, 0.24, 4.0), Color("5b3528"), Vector3(0, 0, 7.0 * side))
		_create_static_box(Vector3(x, 0.8, 6.7), Vector3(4.0, 1.6, 0.38), Color("9a6330"))
		_create_static_box(Vector3(x + 1.8 * side, 0.8, 5.0), Vector3(0.38, 1.6, 3.5), wood)
	_create_static_box(Vector3(-3.9, 0.9, 0.8), Vector3(0.42, 1.8, 5.0), Color("7b5433"))
	_create_static_box(Vector3(3.9, 0.9, -0.8), Vector3(0.42, 1.8, 5.0), Color("7b5433"))
	_create_static_box(Vector3(0, 0.72, 0), Vector3(3.3, 1.44, 0.42), Color("a46b32"))
	_create_static_box(Vector3(-14.8, 0.75, 2.2), Vector3(3.4, 1.5, 0.45), Color("9a6330"))
	_create_static_box(Vector3(14.8, 0.75, -2.2), Vector3(3.4, 1.5, 0.45), Color("9a6330"))

func _build_saloon():
	blue_spawns = [
		Vector3(-5.2, 0.1, -19.0), Vector3(-1.8, 0.1, -19.4),
		Vector3(1.8, 0.1, -19.4), Vector3(5.2, 0.1, -19.0)
	]
	red_spawns = [
		Vector3(-5.2, 0.1, 19.0), Vector3(-1.8, 0.1, 19.4),
		Vector3(1.8, 0.1, 19.4), Vector3(5.2, 0.1, 19.0)
	]
	_create_static_box(Vector3(0, -0.3, 0), Vector3(54, 0.6, 44), Color("c98d4c"))
	_create_boundaries(54, 44)
	_create_team_pad(Vector3(0, 0.02, -18.0), Color("2d9cff"), 4.4)
	_create_team_pad(Vector3(0, 0.02, 18.0), Color("ff3d68"), 4.4)
	_create_spawn_gate(-1, Color("2d9cff"))
	_create_spawn_gate(1, Color("ff3d68"))
	_create_saloon_building()
	_create_saloon_cover()
	_create_control_point()
	_create_cloud(Vector3(-14, 12, -6), 1.2)
	_create_cloud(Vector3(3, 13, 4), 1.45)
	if SaveData.graphics_quality != "low":
		_create_cloud(Vector3(17, 11.5, -2), 0.9)

func _create_spawn_gate(sign_value, team_color):
	var z = 16.2 * sign_value
	var wall_color = Color("8d5d32")
	_create_static_box(Vector3(-10.5, 1.2, z), Vector3(11.0, 2.4, 0.45), wall_color)
	_create_static_box(Vector3(0, 1.2, z), Vector3(4.0, 2.4, 0.45), wall_color)
	_create_static_box(Vector3(10.5, 1.2, z), Vector3(11.0, 2.4, 0.45), wall_color)
	_create_visual_box(Vector3(-5.2, 2.55, z), Vector3(4.0, 0.18, 0.22), team_color)
	_create_visual_box(Vector3(5.2, 2.55, z), Vector3(4.0, 0.18, 0.22), team_color)

func _create_saloon_building():
	var wall = Color("8f4f31")
	var trim = Color("e3c08b")
	var dark = Color("4a2d22")
	# Side walls and front/back sections leave two wide team entrances.
	_create_static_box(Vector3(-10.0, 2.7, 0), Vector3(0.45, 5.4, 13.5), wall)
	_create_static_box(Vector3(10.0, 2.7, 0), Vector3(0.45, 5.4, 13.5), wall)
	for z_sign in [-1.0, 1.0]:
		var z = 6.75 * z_sign
		_create_static_box(Vector3(-7.8, 2.1, z), Vector3(4.0, 4.2, 0.4), wall)
		_create_static_box(Vector3(0, 3.65, z), Vector3(4.2, 1.1, 0.4), wall)
		_create_static_box(Vector3(7.8, 2.1, z), Vector3(4.0, 4.2, 0.4), wall)
		_create_visual_box(Vector3(0, 4.75, z + 0.03 * z_sign), Vector3(5.8, 0.22, 0.22), trim)
	_create_visual_box(Vector3(-5.0, 5.65, 0), Vector3(10.5, 0.35, 14.6), dark, Vector3(0, 0, -8))
	_create_visual_box(Vector3(5.0, 5.65, 0), Vector3(10.5, 0.35, 14.6), dark, Vector3(0, 0, 8))
	# Bar counter on the ground floor.
	_create_static_box(Vector3(-5.8, 1.0, 1.2), Vector3(5.6, 2.0, 0.75), Color("6b3d26"))
	_create_static_box(Vector3(-8.0, 1.0, -1.2), Vector3(0.75, 2.0, 4.2), Color("6b3d26"))
	for x in [-7.5, -5.8, -4.1]:
		_create_visual_box(Vector3(x, 2.18, 1.2), Vector3(0.16, 0.45, 0.16), trim)
	# Second floor balcony with a central opening and a walkable ramp.
	_create_static_box(Vector3(-5.5, 3.35, 0), Vector3(8.5, 0.28, 12.0), Color("7b4a2d"))
	_create_static_box(Vector3(5.5, 3.35, 0), Vector3(5.5, 0.28, 12.0), Color("7b4a2d"))
	_create_static_box(Vector3(7.2, 1.68, 1.2), Vector3(2.0, 0.3, 7.3), Color("8b5a2b"), Vector3(-24, 0, 0))
	for z in [-5.6, -2.0, 2.0, 5.6]:
		_create_visual_box(Vector3(-1.1, 4.0, z), Vector3(0.18, 1.25, 0.18), trim)
		_create_visual_box(Vector3(2.7, 4.0, z), Vector3(0.18, 1.25, 0.18), trim)
	_create_visual_box(Vector3(0.8, 3.55, -5.7), Vector3(7.8, 0.18, 0.18), trim)
	_create_visual_box(Vector3(0.8, 3.55, 5.7), Vector3(7.8, 0.18, 0.18), trim)
	# SALOON sign.
	var sign = Label3D.new()
	sign.text = "SALOON"
	sign.position = Vector3(0, 4.85, -6.98)
	sign.rotation_degrees.y = 180
	sign.font_size = 90
	sign.outline_size = 12
	sign.modulate = Color("ffca3a")
	add_child(sign)

func _create_saloon_cover():
	for item in [
		[Vector3(-15, 0.75, -8), Vector3(3.2, 1.5, 0.5)],
		[Vector3(15, 0.75, 8), Vector3(3.2, 1.5, 0.5)],
		[Vector3(-15, 0.75, 8), Vector3(0.5, 1.5, 3.2)],
		[Vector3(15, 0.75, -8), Vector3(0.5, 1.5, 3.2)],
		[Vector3(-4.0, 0.65, -10.2), Vector3(2.1, 1.3, 1.8)],
		[Vector3(4.0, 0.65, 10.2), Vector3(2.1, 1.3, 1.8)]
	]:
		_create_static_box(item[0], item[1], Color("8b5a2b"))
	for x in [-19.5, 19.5]:
		_create_static_box(Vector3(x, 1.0, 0), Vector3(2.6, 2.0, 7.0), Color("b16e36"))

func _create_control_point():
	zone_position = Vector3(0, 0.06, 0)
	zone_mesh = MeshInstance3D.new()
	zone_mesh.position = zone_position
	var mesh = CylinderMesh.new()
	mesh.top_radius = zone_radius
	mesh.bottom_radius = zone_radius
	mesh.height = 0.08
	mesh.radial_segments = 48
	zone_mesh.mesh = mesh
	zone_material = StandardMaterial3D.new()
	zone_material.albedo_color = Color(0.55, 0.58, 0.62, 0.7)
	zone_material.emission_enabled = true
	zone_material.emission = Color(0.3, 0.32, 0.35, 0.18)
	zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_mesh.material_override = zone_material
	add_child(zone_mesh)

func _update_control_zone(delta):
	var blue_inside = []
	var red_inside = []
	for actor in get_tree().get_nodes_in_group("combatants"):
		if not is_instance_valid(actor) or not actor.alive:
			continue
		var flat_distance = Vector2(actor.global_position.x - zone_position.x, actor.global_position.z - zone_position.z).length()
		if flat_distance <= zone_radius:
			actor.zone_seconds += delta
			if actor.team == 0:
				blue_inside.append(actor)
			else:
				red_inside.append(actor)
	zone_contested = not blue_inside.is_empty() and not red_inside.is_empty()
	if zone_contested:
		zone_score_accumulator = 0.0
		_update_zone_material()
		return
	var active_team = -1
	var active_actors = []
	if not blue_inside.is_empty():
		active_team = 0
		active_actors = blue_inside
	elif not red_inside.is_empty():
		active_team = 1
		active_actors = red_inside

	if active_team < 0:
		zone_capture_progress = max(0.0, zone_capture_progress - delta * 0.35)
		if zone_capture_progress <= 0.0:
			zone_capture_team = -1
		_update_zone_material()
		return

	if zone_owner == active_team:
		zone_capture_team = active_team
		zone_capture_progress = 5.0
		zone_score_accumulator += delta
		while zone_score_accumulator >= 1.0:
			zone_score_accumulator -= 1.0
			_add_team_score(active_team, 5)
	else:
		zone_score_accumulator = 0.0
		if zone_capture_team != active_team:
			zone_capture_team = active_team
			zone_capture_progress = 0.0
		zone_capture_progress += delta
		if zone_capture_progress >= 5.0:
			zone_owner = active_team
			zone_capture_progress = 5.0
			for actor in active_actors:
				actor.captures += 1
			hud.show_center_message("СИНИЕ ЗАХВАТИЛИ ТОЧКУ" if active_team == 0 else "КРАСНЫЕ ЗАХВАТИЛИ ТОЧКУ", 1.4)
	_update_zone_material()

func _update_zone_material():
	if not is_instance_valid(zone_material):
		return
	var color = Color(0.55, 0.58, 0.62, 0.72)
	if zone_owner == 0:
		color = Color(0.18, 0.55, 1.0, 0.76)
	elif zone_owner == 1:
		color = Color(1.0, 0.18, 0.34, 0.76)
	elif zone_capture_team == 0:
		color = Color(0.35, 0.65, 1.0, 0.66)
	elif zone_capture_team == 1:
		color = Color(1.0, 0.42, 0.48, 0.66)
	if zone_contested:
		color = Color(1.0, 0.72, 0.16, 0.78)
	zone_material.albedo_color = color
	zone_material.emission = Color(color, 0.28)

func _create_boundaries(width, depth):
	_create_static_box(Vector3(0, 2.0, -depth * 0.5 - 0.2), Vector3(width, 4, 0.5), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(0, 2.0, depth * 0.5 + 0.2), Vector3(width, 4, 0.5), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(-width * 0.5 - 0.2, 2.0, 0), Vector3(0.5, 4, depth), Color.TRANSPARENT, Vector3.ZERO, false)
	_create_static_box(Vector3(width * 0.5 + 0.2, 2.0, 0), Vector3(0.5, 4, depth), Color.TRANSPARENT, Vector3.ZERO, false)

func _create_barn(base, opening_sign, team_color):
	var wall_color = Color("a94f3d")
	var trim_color = Color("f3e3c3")
	var roof_color = Color("5b3528")
	var back_z = base.z - 1.65 * opening_sign
	var front_z = base.z + 1.65 * opening_sign
	_create_static_box(Vector3(base.x, 1.8, back_z), Vector3(10.2, 3.6, 0.35), wall_color)
	_create_static_box(Vector3(base.x - 4.95, 1.7, base.z), Vector3(0.35, 3.4, 3.65), wall_color)
	_create_static_box(Vector3(base.x + 4.95, 1.7, base.z), Vector3(0.35, 3.4, 3.65), wall_color)
	_create_static_box(Vector3(base.x - 3.15, 0.65, front_z), Vector3(3.3, 1.3, 0.28), trim_color)
	_create_static_box(Vector3(base.x + 3.15, 0.65, front_z), Vector3(3.3, 1.3, 0.28), trim_color)
	_create_visual_box(Vector3(base.x - 2.4, 4.0, base.z), Vector3(5.8, 0.36, 4.3), roof_color, Vector3(0, 0, -24))
	_create_visual_box(Vector3(base.x + 2.4, 4.0, base.z), Vector3(5.8, 0.36, 4.3), roof_color, Vector3(0, 0, 24))
	_create_visual_box(Vector3(base.x, 2.95, front_z + 0.03 * opening_sign), Vector3(2.2, 0.22, 0.22), team_color)

func _create_grass_patches(width, depth):
	var patch_count = 18 if SaveData.graphics_quality == "low" else 48 if SaveData.graphics_quality == "medium" else 92
	for i in range(patch_count):
		var x = randf_range(-width + 1.0, width - 1.0)
		var z = randf_range(-depth + 1.0, depth - 1.0)
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
		if cloud.position.x > 30.0:
			cloud.position.x = -30.0

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

func _create_team_pad(pos, color, radius = 3.4):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.position = pos
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
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
		bot.setup_bot(self, 0, blue_names[i], blue_spawns[i + 1], weapons.pick_random(), i + 1)
	var red_names = ["Кобра", "Титан", "Рейд", "Фантом"]
	for i in range(4):
		var bot = BotScript.new()
		add_child(bot)
		bot.setup_bot(self, 1, red_names[i], red_spawns[i], weapons.pick_random(), i)

func find_nearest_enemy(actor):
	var best
	var best_score = INF
	for candidate in get_tree().get_nodes_in_group("combatants"):
		if candidate == actor or not candidate.alive or candidate.team == actor.team:
			continue
		var distance = actor.global_position.distance_squared_to(candidate.global_position)
		if mode_id == "saloon":
			var zone_distance = candidate.global_position.distance_squared_to(zone_position)
			distance += zone_distance * 0.18
		if distance < best_score:
			best_score = distance
			best = candidate
	return best

func get_bot_objective(actor):
	if mode_id == "saloon":
		var team_sign = -1.0 if actor.team == 0 else 1.0
		if zone_owner != actor.team:
			var attack_offsets = [Vector3(-2.2, 0, 0), Vector3(2.2, 0, 0), Vector3(0, 0, -2.1 * team_sign), Vector3(0, 0, 2.1 * team_sign)]
			return zone_position + attack_offsets[actor.role_index % attack_offsets.size()]
		var defend_offsets = [Vector3(-4.8, 0, -1.6), Vector3(4.8, 0, 1.6), Vector3(-1.5, 0, 4.8 * team_sign), Vector3(6.6, 0, -3.0 * team_sign)]
		return zone_position + defend_offsets[actor.role_index % defend_offsets.size()]
	var lane_x = [-10.0, -3.5, 3.5, 10.0][actor.role_index % 4]
	var advance_z = 3.0 if actor.team == 0 else -3.0
	return Vector3(lane_x, 0.1, advance_z)

func register_kill(killer, victim, hit_info = {}):
	if not match_active:
		return
	victim.deaths += 1
	victim.life_streak = 0
	var valid_killer = is_instance_valid(killer) and killer is Combatant and killer.team != victim.team
	var assistants = []
	if valid_killer:
		assistants = victim.collect_assist_candidates(killer, 10.0)
		killer.kills += 1
		killer.life_streak += 1
		killer.best_streak = max(killer.best_streak, killer.life_streak)
	for assister in assistants:
		assister.assists += 1
		if assister == player:
			match_coins += 10
	victim.clear_damage_contributors()

	var added_points = 1
	var event_parts = []
	if mode_id == "saloon":
		added_points = _calculate_saloon_kill_points(killer, hit_info, valid_killer, event_parts)
		var scoring_team = killer.team if valid_killer else 1 - victim.team
		_add_team_score(scoring_team, added_points)
		if valid_killer:
			killer.score_points += added_points
	else:
		if valid_killer:
			_add_team_score(killer.team, 1)
		else:
			_add_team_score(1 - victim.team, 1)

	var killer_name = "Окружение"
	if valid_killer:
		killer_name = killer.actor_name
		if killer == player:
			match_coins += 20
	var feed = "%s → %s" % [killer_name, victim.actor_name]
	if mode_id == "saloon":
		feed += "  +%d очк." % added_points
	if not event_parts.is_empty():
		feed += "  • %s" % " • ".join(event_parts)
	if not assistants.is_empty():
		var assist_names = []
		for assister in assistants:
			assist_names.append(assister.actor_name)
		feed += "  • ассист: %s" % ", ".join(assist_names)
	hud.show_center_message(feed, 1.35)

	if blue_score >= score_limit or red_score >= score_limit:
		finish_match(false)
	else:
		_respawn_later(victim)

func _calculate_saloon_kill_points(killer, hit_info, valid_killer, event_parts):
	if not valid_killer:
		return 10
	var method = str(hit_info.get("method", "weapon"))
	var headshot = bool(hit_info.get("headshot", false))
	var points = 15 if method == "knife" else 10
	if not first_blood_taken:
		first_blood_taken = true
		points = 20
		event_parts.append("FIRST BLOOD")
	if headshot:
		points += 25
		event_parts.append("В ГОЛОВУ +25")
	var streak = int(killer.life_streak)
	var streak_bonus = 0
	var streak_name = ""
	if streak == 2:
		streak_bonus = 10
		streak_name = "DOUBLE KILL"
	elif streak == 3:
		streak_bonus = 20
		streak_name = "TRIPLE KILL"
	elif streak == 4:
		streak_bonus = 30
		streak_name = "QUAD KILL"
	elif streak == 5:
		streak_bonus = 50
		streak_name = "UNSTOPPABLE"
	elif streak > 5:
		streak_bonus = 20
		streak_name = "UNSTOPPABLE ×%d" % streak
	points += streak_bonus
	if not streak_name.is_empty():
		event_parts.append("%s +%d" % [streak_name, streak_bonus])
	return points

func _add_team_score(team_value, amount):
	if team_value == 0:
		blue_score = mini(score_limit, blue_score + int(amount))
	else:
		red_score = mini(score_limit, red_score + int(amount))
	if blue_score >= score_limit or red_score >= score_limit:
		call_deferred("finish_match", false)

func _respawn_later(actor):
	await get_tree().create_timer(2.8).timeout
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
			reward += 220 if mode_id == "saloon" else 150
		elif draw:
			reward += 100
		else:
			reward += 70 if mode_id == "saloon" else 60
	SaveData.add_coins(reward)
	var xp_reward = 0
	var progression = {"leveled_up": false, "level": SaveData.player_level, "xp": SaveData.experience}
	if not aborted:
		xp_reward = 130 + player.kills * 7 + player.assists * 4 + int(player.zone_seconds * 0.45) + (70 if won else 25 if draw else 12)
		progression = SaveData.add_experience(xp_reward)
	var title = "БОЙ ПРЕРВАН"
	if not aborted:
		title = "НИЧЬЯ" if draw else ("ПОБЕДА!" if won else "ПОРАЖЕНИЕ")
	await get_tree().create_timer(0.45).timeout
	results_visible = true
	hud.show_match_results(title, blue_score, red_score, _collect_statistics(), reward, match_elapsed, xp_reward, progression, mode_id)

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
			"points": actor.score_points,
			"streak": actor.best_streak,
			"captures": actor.captures,
			"zone_seconds": int(actor.zone_seconds),
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
	if int(a["points"]) != int(b["points"]):
		return int(a["points"]) > int(b["points"])
	if int(a["kills"]) == int(b["kills"]):
		if int(a["assists"]) == int(b["assists"]):
			return int(a["deaths"]) < int(b["deaths"])
		return int(a["assists"]) > int(b["assists"])
	return int(a["kills"]) > int(b["kills"])

func _on_continue_pressed():
	if results_visible:
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
	if is_instance_valid(grenade_audio):
		grenade_audio.global_position = position
		grenade_audio.play()
	var radius = 4.5
	for actor in get_tree().get_nodes_in_group("combatants"):
		if not is_instance_valid(actor) or not actor.alive or actor.team == owner.team:
			continue
		if actor.global_position.distance_to(position) <= radius and _blast_has_line(position, actor):
			actor.take_damage(SaveData.GRENADE_DAMAGE, owner, {"method": "grenade", "headshot": false})
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
