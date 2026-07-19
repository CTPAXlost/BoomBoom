extends "res://scripts/game/combatant.gd"
class_name BotCombatant

var target
var speed = 4.05
var fire_ready = 0.0
var retarget_ready = 0.0
var strafe_sign = 1.0
var weapon_id = "rifle"
var role_index = 0
var body_root
var torso_mesh
var head_mesh
var left_arm
var right_arm
var left_leg
var right_leg
var weapon_root
var muzzle = Vector3.ZERO
var name_label
var weapon_label
var animation_time = 0.0
var bot_mag = 0
var bot_reserve = 0
var reloading = false
var reload_finish_time = 0.0
var shot_audio
var reload_audio
var footstep_audio
var footstep_timer = 0.0
var footstep_index = 0

const FOOTSTEP_SOUND_PATHS = [
	"res://assets/audio/footstep1.wav",
	"res://assets/audio/footstep2.wav"
]
const RELOAD_SOUND_PATH = "res://assets/audio/reload.wav"

func _load_audio(path):
	if path == null or str(path).is_empty():
		return null
	return ResourceLoader.load(str(path), "AudioStream", ResourceLoader.CACHE_MODE_REUSE)

func _ready():
	_build_body()

func _build_body():
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)

	body_root = Node3D.new()
	add_child(body_root)

	torso_mesh = _body_box(Vector3(0, 1.34, 0), Vector3(0.68, 0.78, 0.34), Color.WHITE)
	body_root.add_child(torso_mesh)
	var chest_plate = _body_box(Vector3(0, 1.42, -0.2), Vector3(0.5, 0.48, 0.09), Color("303944"))
	body_root.add_child(chest_plate)
	var hips = _body_box(Vector3(0, 0.9, 0), Vector3(0.56, 0.22, 0.3), Color("29313a"))
	body_root.add_child(hips)

	head_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	head_mesh.mesh = sphere
	head_mesh.position = Vector3(0, 1.92, 0)
	body_root.add_child(head_mesh)
	var helmet = _body_box(Vector3(0, 2.09, 0), Vector3(0.48, 0.18, 0.48), Color("26313a"))
	body_root.add_child(helmet)

	left_arm = _limb_pivot(Vector3(-0.47, 1.62, 0), Vector3(0.18, 0.62, 0.2), Color.WHITE)
	right_arm = _limb_pivot(Vector3(0.47, 1.62, 0), Vector3(0.18, 0.62, 0.2), Color.WHITE)
	left_leg = _limb_pivot(Vector3(-0.19, 0.78, 0), Vector3(0.22, 0.74, 0.25), Color("26313a"))
	right_leg = _limb_pivot(Vector3(0.19, 0.78, 0), Vector3(0.22, 0.74, 0.25), Color("26313a"))
	body_root.add_child(left_arm)
	body_root.add_child(right_arm)
	body_root.add_child(left_leg)
	body_root.add_child(right_leg)

	weapon_root = Node3D.new()
	weapon_root.position = Vector3(0.2, 1.42, -0.38)
	weapon_root.rotation_degrees = Vector3(0, 0, -4)
	body_root.add_child(weapon_root)

	shot_audio = AudioStreamPlayer3D.new()
	shot_audio.max_distance = 46.0
	shot_audio.unit_size = 4.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer3D.new()
	reload_audio.stream = _load_audio(RELOAD_SOUND_PATH)
	reload_audio.max_distance = 22.0
	add_child(reload_audio)
	footstep_audio = AudioStreamPlayer3D.new()
	footstep_audio.max_distance = 11.0
	footstep_audio.volume_db = -10.0
	add_child(footstep_audio)

	name_label = Label3D.new()
	name_label.position.y = 2.5
	name_label.font_size = 28
	name_label.outline_size = 8
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)

	weapon_label = Label3D.new()
	weapon_label.position.y = 2.22
	weapon_label.font_size = 18
	weapon_label.outline_size = 6
	weapon_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	weapon_label.modulate = Color("ffca3a")
	add_child(weapon_label)

func _body_box(pos, size_value, color):
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.68
	mesh_instance.material_override = mat
	return mesh_instance

func _limb_pivot(pos, size_value, color):
	var pivot = Node3D.new()
	pivot.position = pos
	var limb = _body_box(Vector3(0, -size_value.y * 0.5, 0), size_value, color)
	pivot.add_child(limb)
	return pivot

func setup_bot(p_game, p_team, p_name, p_spawn, p_weapon = "rifle", p_role_index = 0):
	setup(p_game, p_team, p_name, p_spawn)
	weapon_id = p_weapon if SaveData.main_weapon_ids().has(p_weapon) else "rifle"
	role_index = int(p_role_index)
	if not is_node_ready():
		await ready
	name_label.text = actor_name
	weapon_label.text = SaveData.weapon_catalog()[weapon_id].type
	_apply_team_material()
	_build_weapon_model()
	_reset_ammo()

func _reset_ammo():
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	bot_mag = int(stats.magazine)
	bot_reserve = int(stats.reserve) * 8
	reloading = false
	reload_finish_time = 0.0

func _apply_team_material():
	var team_color = Color("2d9cff") if team == 0 else Color("ff3d68")
	var uniform = StandardMaterial3D.new()
	uniform.albedo_color = team_color
	uniform.roughness = 0.62
	torso_mesh.material_override = uniform
	for arm in [left_arm, right_arm]:
		var limb = arm.get_child(0)
		if limb is MeshInstance3D:
			limb.material_override = uniform
	var skin = StandardMaterial3D.new()
	skin.albedo_color = Color("d8a37a")
	skin.roughness = 0.82
	head_mesh.material_override = skin

func _build_weapon_model():
	for child in weapon_root.get_children():
		child.queue_free()
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	var color = stats.color
	if weapon_id == "shotgun":
		_add_weapon_box(Vector3(0, 0, -0.15), Vector3(0.17, 0.15, 0.72), color)
		_add_weapon_box(Vector3(0, 0, -0.66), Vector3(0.07, 0.07, 0.42), Color("20262d"))
		_add_weapon_box(Vector3(0, -0.08, 0.28), Vector3(0.18, 0.18, 0.3), Color("6a4327"))
		muzzle = Vector3(0, 0, -0.92)
	elif weapon_id == "machinegun":
		_add_weapon_box(Vector3(0, 0, -0.12), Vector3(0.22, 0.2, 0.78), color)
		_add_weapon_box(Vector3(0, 0, -0.7), Vector3(0.08, 0.08, 0.48), Color("20262d"))
		_add_weapon_box(Vector3(0, -0.19, 0.05), Vector3(0.25, 0.34, 0.28), Color("333b45"))
		muzzle = Vector3(0, 0, -0.98)
	elif weapon_id == "sniper":
		_add_weapon_box(Vector3(0, 0, -0.18), Vector3(0.15, 0.14, 0.92), color)
		_add_weapon_box(Vector3(0, 0, -0.88), Vector3(0.055, 0.055, 0.65), Color("20262d"))
		_add_weapon_box(Vector3(0, 0.13, -0.26), Vector3(0.12, 0.12, 0.46), Color("111820"))
		_add_weapon_box(Vector3(0, -0.04, 0.38), Vector3(0.18, 0.16, 0.36), Color("5d3b24"))
		muzzle = Vector3(0, 0, -1.25)
	else:
		var length = 0.66
		if weapon_id == "rifle_vortex":
			length = 0.72
		elif weapon_id == "rifle_bastion":
			length = 0.78
		elif weapon_id == "rifle_phoenix":
			length = 0.84
		_add_weapon_box(Vector3(0, 0, -0.16), Vector3(0.18, 0.16, length), color)
		_add_weapon_box(Vector3(0, 0, -0.62), Vector3(0.065, 0.065, 0.38), Color("20262d"))
		_add_weapon_box(Vector3(0, -0.14, 0.22), Vector3(0.16, 0.28, 0.25), Color("303944"))
		muzzle = Vector3(0, 0, -0.84 - max(0.0, length - 0.66) * 0.5)

func _add_weapon_box(pos, size_value, color):
	var mesh_instance = _body_box(pos, size_value, color)
	var mat = mesh_instance.material_override
	mat.metallic = 0.38
	mat.roughness = 0.3
	weapon_root.add_child(mesh_instance)

func _physics_process(delta):
	if not alive or not is_instance_valid(game) or not game.match_active:
		return
	if not game.combat_enabled:
		velocity = Vector3.ZERO
		_animate_body(delta, false)
		return
	var now = Time.get_ticks_msec() * 0.001
	if reloading and now >= reload_finish_time:
		_finish_reload()
	if not is_instance_valid(target) or not target.alive or now >= retarget_ready:
		target = game.find_nearest_enemy(self)
		retarget_ready = now + randf_range(0.35, 0.75)
		if randf() < 0.28:
			strafe_sign *= -1.0

	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	var objective = game.get_bot_objective(self)
	var desired = Vector3.ZERO
	var can_engage = false
	var distance = INF
	var flat = Vector3.ZERO
	if is_instance_valid(target):
		var to_target = target.global_position - global_position
		distance = to_target.length()
		flat = Vector3(to_target.x, 0.0, to_target.z)
		can_engage = distance <= float(stats.range) * 1.08 and _has_line_of_sight(target)
		if can_engage and flat.length() > 0.01:
			look_at(global_position + flat, Vector3.UP)

	if can_engage:
		var ideal_distance = 12.0
		if weapon_id == "shotgun":
			ideal_distance = 4.2
		elif weapon_id == "machinegun":
			ideal_distance = 18.0
		elif weapon_id == "sniper":
			ideal_distance = 31.0
		elif SaveData.automatic_weapon_ids().has(weapon_id):
			ideal_distance = min(16.0, float(stats.range) * 0.65)
		if distance > ideal_distance + 1.8:
			desired += flat.normalized()
		elif distance < max(2.2, ideal_distance - 2.0):
			desired -= flat.normalized() * 0.62
		var side = flat.normalized().cross(Vector3.UP) * strafe_sign
		desired += side * (0.34 if weapon_id == "sniper" else 0.48)
	else:
		var to_objective = objective - global_position
		var flat_objective = Vector3(to_objective.x, 0.0, to_objective.z)
		if flat_objective.length() > 0.8:
			desired = flat_objective.normalized()
			look_at(global_position + flat_objective, Vector3.UP)

	desired = _with_team_separation(desired)
	if desired.length() > 1.0:
		desired = desired.normalized()
	var target_velocity = desired * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, delta * 12.0)
	velocity.z = move_toward(velocity.z, target_velocity.z, delta * 12.0)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	var moving = Vector2(velocity.x, velocity.z).length() > 0.25
	_animate_body(delta, moving)
	_update_footsteps(delta, moving)

	if can_engage and not reloading and now >= fire_ready:
		if bot_mag <= 0:
			_start_reload(stats)
		else:
			shoot(target)

func _with_team_separation(current_desired):
	var push = Vector3.ZERO
	for ally in get_tree().get_nodes_in_group("team_%d" % team):
		if ally == self or not is_instance_valid(ally) or not ally.alive:
			continue
		var offset = global_position - ally.global_position
		offset.y = 0.0
		var distance = offset.length()
		if distance > 0.01 and distance < 1.35:
			push += offset.normalized() * (1.35 - distance)
	return current_desired + push * 0.5

func _animate_body(delta, moving):
	var blend = min(1.0, delta * 10.0)
	if moving:
		animation_time += delta * 7.0
	var swing = sin(animation_time) * 24.0 if moving else 0.0
	left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, swing, blend)
	right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, -swing, blend)
	left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, -swing * 0.32 - 42.0, blend)
	right_arm.rotation_degrees.x = lerp(right_arm.rotation_degrees.x, swing * 0.2 - 52.0, blend)
	left_arm.rotation_degrees.z = lerp(left_arm.rotation_degrees.z, -18.0, blend)
	right_arm.rotation_degrees.z = lerp(right_arm.rotation_degrees.z, 18.0, blend)
	body_root.position.y = lerp(body_root.position.y, abs(sin(animation_time * 2.0)) * 0.022 if moving else 0.0, blend)
	weapon_root.position.y = 1.42 + (sin(animation_time * 2.0) * 0.016 if moving else 0.0)

func _update_footsteps(delta, moving):
	if not moving:
		footstep_timer = min(footstep_timer, 0.2)
		return
	footstep_timer -= delta
	if footstep_timer <= 0.0 and is_instance_valid(footstep_audio):
		footstep_audio.stream = _load_audio(FOOTSTEP_SOUND_PATHS[footstep_index % FOOTSTEP_SOUND_PATHS.size()])
		footstep_index += 1
		footstep_audio.pitch_scale = randf_range(0.92, 1.08)
		footstep_audio.play()
		footstep_timer = 0.55

func _has_line_of_sight(enemy):
	var origin = global_position + Vector3.UP * 1.45
	var destination = enemy.global_position + Vector3.UP * 1.15
	var query = PhysicsRayQueryParameters3D.create(origin, destination)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == enemy

func _start_reload(stats):
	if reloading or bot_reserve <= 0:
		return
	reloading = true
	reload_finish_time = Time.get_ticks_msec() * 0.001 + float(stats.reload_time)
	fire_ready = reload_finish_time
	if is_instance_valid(reload_audio):
		reload_audio.pitch_scale = clamp(2.4 / max(float(stats.reload_time), 0.2), 0.62, 1.35)
		reload_audio.play()
	weapon_label.text = "ПЕРЕЗАРЯДКА %.0fс" % float(stats.reload_time)

func _finish_reload():
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	var needed = int(stats.magazine) - bot_mag
	var loaded = min(needed, bot_reserve)
	bot_mag += loaded
	bot_reserve -= loaded
	reloading = false
	weapon_label.text = SaveData.weapon_catalog()[weapon_id].type

func shoot(enemy):
	if not game.combat_enabled or reloading or bot_mag <= 0:
		return
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	bot_mag -= 1
	fire_ready = Time.get_ticks_msec() * 0.001 + float(stats.fire_rate) * randf_range(1.0, 1.38)
	var distance = global_position.distance_to(enemy.global_position)
	var range_ratio = clamp(distance / max(float(stats.range), 0.01), 0.0, 1.0)
	var accuracy = 0.8 - range_ratio * 0.28
	if weapon_id == "shotgun":
		accuracy = 0.92 - range_ratio * 0.52
	elif weapon_id == "machinegun":
		accuracy = 0.72 - range_ratio * 0.25
	elif weapon_id == "sniper":
		accuracy = 0.9 - range_ratio * 0.18
	accuracy = clamp(accuracy, 0.26, 0.94)

	var start = weapon_root.to_global(muzzle)
	var finish = enemy.global_position + Vector3.UP * 1.15
	var did_hit = false
	var headshot = false
	var total_damage = 0.0
	if weapon_id == "shotgun":
		var falloff = lerp(1.0, 0.25, range_ratio)
		for pellet_index in range(int(stats.pellets)):
			if randf() <= accuracy:
				total_damage += float(stats.damage) * falloff
		did_hit = total_damage > 0.0
		headshot = did_hit and randf() < 0.045
		if headshot:
			total_damage *= float(stats.headshot_multiplier)
	else:
		did_hit = randf() <= accuracy
		if did_hit:
			total_damage = float(stats.damage)
			headshot = randf() < (0.12 if weapon_id == "sniper" else 0.075)
			if headshot:
				total_damage *= float(stats.headshot_multiplier)

	if is_instance_valid(shot_audio):
		shot_audio.stream = _load_audio(str(stats.sound))
		shot_audio.pitch_scale = randf_range(0.96, 1.04)
		shot_audio.play()
	if did_hit:
		enemy.take_damage(total_damage, self, {"method": weapon_id, "headshot": headshot})
	else:
		finish += Vector3(randf_range(-1.4, 1.4), randf_range(-0.8, 1.2), randf_range(-1.4, 1.4))
	if game:
		game.spawn_tracer(start, finish, stats.color, did_hit)
	if bot_mag <= 0 and bot_reserve > 0:
		_start_reload(stats)

func on_respawned():
	target = null
	fire_ready = Time.get_ticks_msec() * 0.001 + 0.8
	_reset_ammo()
