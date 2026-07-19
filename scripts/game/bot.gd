extends Combatant
class_name BotCombatant

var target
var speed = 4.7
var fire_ready = 0.0
var retarget_ready = 0.0
var strafe_sign = 1.0
var weapon_id = "rifle"
var body_root
var torso_mesh
var head_mesh
var left_arm
var right_arm
var left_leg
var right_leg
var weapon_root
var muzzle
var name_label
var weapon_label
var animation_time = 0.0

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

func setup_bot(p_game, p_team, p_name, p_spawn, p_weapon = "rifle"):
	setup(p_game, p_team, p_name, p_spawn)
	weapon_id = p_weapon if SaveData.main_weapon_ids().has(p_weapon) else "rifle"
	if not is_node_ready():
		await ready
	name_label.text = actor_name
	weapon_label.text = SaveData.weapon_catalog()[weapon_id].type
	_apply_team_material()
	_build_weapon_model()

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
		_add_weapon_box(Vector3(0, 0, -0.16), Vector3(0.18, 0.16, 0.66), color)
		_add_weapon_box(Vector3(0, 0, -0.62), Vector3(0.065, 0.065, 0.38), Color("20262d"))
		_add_weapon_box(Vector3(0, -0.14, 0.22), Vector3(0.16, 0.28, 0.25), Color("303944"))
		muzzle = Vector3(0, 0, -0.84)

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
	if not is_instance_valid(target) or not target.alive or now >= retarget_ready:
		target = game.find_nearest_enemy(self)
		retarget_ready = now + randf_range(0.35, 0.75)
		if randf() < 0.25:
			strafe_sign *= -1.0
	if not is_instance_valid(target):
		return

	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var flat = Vector3(to_target.x, 0.0, to_target.z)
	if flat.length() > 0.01:
		look_at(global_position + flat, Vector3.UP)

	var ideal_distance = 12.0
	if weapon_id == "shotgun":
		ideal_distance = 4.2
	elif weapon_id == "machinegun":
		ideal_distance = 18.0
	elif weapon_id == "sniper":
		ideal_distance = 32.0

	var desired = Vector3.ZERO
	if flat.length() > 0.01:
		if distance > ideal_distance + 1.8:
			desired += flat.normalized()
		elif distance < max(2.2, ideal_distance - 2.0):
			desired -= flat.normalized() * 0.68
		var side = flat.normalized().cross(Vector3.UP) * strafe_sign
		if distance < float(stats.range) + 3.0:
			desired += side * (0.36 if weapon_id == "sniper" else 0.54 if weapon_id == "machinegun" else 0.68)
	if desired.length() > 1.0:
		desired = desired.normalized()

	velocity.x = desired.x * speed
	velocity.z = desired.z * speed
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	_animate_body(delta, Vector2(velocity.x, velocity.z).length() > 0.25)

	if distance <= float(stats.range) and now >= fire_ready and _has_line_of_sight(target):
		shoot(target)

func _animate_body(delta, moving):
	var blend = min(1.0, delta * 12.0)
	if moving:
		animation_time += delta * 8.5
	var swing = sin(animation_time) * 28.0 if moving else 0.0
	left_leg.rotation_degrees.x = lerp(left_leg.rotation_degrees.x, swing, blend)
	right_leg.rotation_degrees.x = lerp(right_leg.rotation_degrees.x, -swing, blend)
	left_arm.rotation_degrees.x = lerp(left_arm.rotation_degrees.x, -swing * 0.38 - 42.0, blend)
	right_arm.rotation_degrees.x = lerp(right_arm.rotation_degrees.x, swing * 0.22 - 52.0, blend)
	left_arm.rotation_degrees.z = lerp(left_arm.rotation_degrees.z, -18.0, blend)
	right_arm.rotation_degrees.z = lerp(right_arm.rotation_degrees.z, 18.0, blend)
	body_root.position.y = lerp(body_root.position.y, abs(sin(animation_time * 2.0)) * 0.025 if moving else 0.0, blend)
	weapon_root.position.y = 1.42 + (sin(animation_time * 2.0) * 0.018 if moving else 0.0)

func _has_line_of_sight(enemy):
	var origin = global_position + Vector3.UP * 1.45
	var destination = enemy.global_position + Vector3.UP * 1.15
	var query = PhysicsRayQueryParameters3D.create(origin, destination)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == enemy

func shoot(enemy):
	if not game.combat_enabled:
		return
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	fire_ready = Time.get_ticks_msec() * 0.001 + float(stats.fire_rate) * randf_range(1.0, 1.45)
	var distance = global_position.distance_to(enemy.global_position)
	var range_ratio = clamp(distance / max(float(stats.range), 0.01), 0.0, 1.0)
	var accuracy = 0.82 - range_ratio * 0.28
	if weapon_id == "shotgun":
		accuracy = 0.92 - range_ratio * 0.52
	elif weapon_id == "machinegun":
		accuracy = 0.74 - range_ratio * 0.25
	elif weapon_id == "sniper":
		accuracy = 0.9 - range_ratio * 0.18
	accuracy = clamp(accuracy, 0.28, 0.94)

	var start = weapon_root.to_global(muzzle)
	var finish = enemy.global_position + Vector3.UP * 1.15
	var did_hit = false
	var total_damage = 0.0
	if weapon_id == "shotgun":
		var falloff = lerp(1.0, 0.25, range_ratio)
		for pellet_index in range(int(stats.pellets)):
			if randf() <= accuracy:
				total_damage += float(stats.damage) * falloff
		did_hit = total_damage > 0.0
	else:
		did_hit = randf() <= accuracy
		if did_hit:
			total_damage = float(stats.damage)
			if weapon_id != "sniper" and randf() < 0.09:
				total_damage *= float(stats.headshot_multiplier)

	if did_hit:
		enemy.take_damage(total_damage, self)
	else:
		finish += Vector3(randf_range(-1.4, 1.4), randf_range(-0.8, 1.2), randf_range(-1.4, 1.4))
	if game:
		game.spawn_tracer(start, finish, stats.color, did_hit)

func on_respawned():
	target = null
	fire_ready = Time.get_ticks_msec() * 0.001 + 0.8
