extends Combatant
class_name BotCombatant

var target
var speed = 4.7
var fire_ready = 0.0
var retarget_ready = 0.0
var strafe_sign = 1.0
var weapon_id = "rifle"
var body_mesh
var name_label
var weapon_label

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

	body_mesh = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.42
	capsule_mesh.height = 1.75
	body_mesh.mesh = capsule_mesh
	body_mesh.position.y = 0.88
	add_child(body_mesh)

	var head_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.29
	sphere.height = 0.58
	head_mesh.mesh = sphere
	head_mesh.position.y = 1.82
	add_child(head_mesh)

	name_label = Label3D.new()
	name_label.position.y = 2.35
	name_label.font_size = 28
	name_label.outline_size = 8
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)

	weapon_label = Label3D.new()
	weapon_label.position.y = 2.08
	weapon_label.font_size = 18
	weapon_label.outline_size = 6
	weapon_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	weapon_label.modulate = Color("ffca3a")
	add_child(weapon_label)

func setup_bot(p_game, p_team, p_name, p_spawn, p_weapon = "rifle"):
	setup(p_game, p_team, p_name, p_spawn)
	weapon_id = p_weapon if SaveData.main_weapon_ids().has(p_weapon) else "rifle"
	if not is_node_ready():
		await ready
	name_label.text = actor_name
	weapon_label.text = SaveData.weapon_catalog()[weapon_id].type
	_apply_team_material()

func _apply_team_material():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("2d9cff") if team == 0 else Color("ff3d68")
	mat.roughness = 0.62
	body_mesh.material_override = mat

func _physics_process(delta):
	if not alive or not is_instance_valid(game) or not game.match_active:
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

	var desired = Vector3.ZERO
	if flat.length() > 0.01:
		if distance > ideal_distance + 1.8:
			desired += flat.normalized()
		elif distance < max(2.2, ideal_distance - 2.0):
			desired -= flat.normalized() * 0.65
		var side = flat.normalized().cross(Vector3.UP) * strafe_sign
		if distance < float(stats.range) + 3.0:
			desired += side * (0.46 if weapon_id == "machinegun" else 0.68)
	if desired.length() > 1.0:
		desired = desired.normalized()

	velocity.x = desired.x * speed
	velocity.z = desired.z * speed
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	if distance <= float(stats.range) and now >= fire_ready and _has_line_of_sight(target):
		shoot(target)

func _has_line_of_sight(enemy):
	var origin = global_position + Vector3.UP * 1.45
	var destination = enemy.global_position + Vector3.UP * 1.15
	var query = PhysicsRayQueryParameters3D.create(origin, destination)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == enemy

func shoot(enemy):
	var stats = SaveData.get_weapon_stats(weapon_id, 1)
	fire_ready = Time.get_ticks_msec() * 0.001 + float(stats.fire_rate) * randf_range(1.0, 1.45)
	var distance = global_position.distance_to(enemy.global_position)
	var range_ratio = clamp(distance / max(float(stats.range), 0.01), 0.0, 1.0)
	var accuracy = 0.82 - range_ratio * 0.28
	if weapon_id == "shotgun":
		accuracy = 0.92 - range_ratio * 0.52
	elif weapon_id == "machinegun":
		accuracy = 0.74 - range_ratio * 0.25
	accuracy = clamp(accuracy, 0.28, 0.9)

	var start = global_position + Vector3.UP * 1.35
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
			if randf() < 0.09:
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
