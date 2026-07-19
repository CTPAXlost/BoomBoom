extends Combatant
class_name PlayerCombatant

var camera
var head
var weapon_root
var knife_root
var muzzle
var muzzle_flash
var muzzle_light
var game_hud
var yaw = 0.0
var pitch = 0.0
var speed = 7.3
var acceleration = 32.0
var deceleration = 42.0
var mouse_sensitivity = 0.0024
var mobile_sensitivity = 0.0036
var look_accumulator = Vector2.ZERO
var current_slot = 0
var current_weapon_id = "rifle"
var weapon_states = {}
var pistol_state = {}
var using_pistol = false
var next_fire_time = 0.0
var reloading = false
var knife_ready_time = 0.0
var target_under_crosshair = false
var recoil = 0.0
var muzzle_flash_time = 0.0
var bob_time = 0.0
var knife_animation_time = 0.0
var knife_animation_duration = 0.42

func _ready():
	_build_body()
	_reset_ammo()

func _build_body():
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)

	head = Node3D.new()
	head.position.y = 1.62
	add_child(head)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 82.0
	camera.near = 0.04
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	head.add_child(camera)

	weapon_root = Node3D.new()
	camera.add_child(weapon_root)
	_build_knife_model()
	_update_weapon_model()

func setup_player(p_game, p_team, p_name, p_spawn, hud):
	setup(p_game, p_team, p_name, p_spawn)
	game_hud = hud
	if not is_node_ready():
		await ready
	set_armor_capacity(SaveData.ARMOR_VALUE if SaveData.armor_owned else 0)
	game_hud.set_player(self)
	_face_towards(Vector3.ZERO)

func _face_towards(target):
	var flat_target = Vector3(target.x, global_position.y, target.z)
	if global_position.distance_squared_to(flat_target) < 0.001:
		return
	look_at(flat_target, Vector3.UP)
	yaw = rotation.y
	pitch = 0.0
	head.rotation.x = 0.0

func _reset_ammo():
	weapon_states.clear()
	for id in ["rifle", "shotgun"]:
		var stats = SaveData.get_weapon_stats(id)
		weapon_states[id] = {"mag": int(stats.magazine), "reserve": int(stats.reserve)}
	var pistol = SaveData.get_weapon_stats("pistol")
	pistol_state = {"mag": int(pistol.magazine), "reserve": int(pistol.reserve)}
	using_pistol = false
	select_first_available_slot()

func select_first_available_slot():
	for i in range(4):
		if SaveData.loadout[i] != "":
			select_slot(i)
			return
	using_pistol = true
	current_weapon_id = "pistol"
	_update_weapon_model()

func _physics_process(delta):
	if not alive:
		_update_weapon_visuals(delta)
		return
	_handle_look(delta)
	_handle_move(delta)
	_handle_actions()
	_update_auto_fire()
	_update_weapon_visuals(delta)

func _handle_move(delta):
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if game_hud:
		input_vec += game_hud.move_vector
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()

	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var direction = right * input_vec.x + forward * -input_vec.y
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		if is_on_floor():
			bob_time += delta * 10.5
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	var moving = Vector2(velocity.x, velocity.z).length() > 0.35 and is_on_floor()
	var bob = sin(bob_time) * 0.022 if moving else 0.0
	head.position.y = lerp(head.position.y, 1.62 + bob, min(1.0, delta * 12.0))

func _handle_look(delta):
	if game_hud:
		look_accumulator += game_hud.consume_look_delta()
	var smoothing = 1.0 - exp(-42.0 * delta)
	var applied = look_accumulator * smoothing
	look_accumulator -= applied
	if applied.length_squared() > 0.0001:
		_apply_look(applied, mobile_sensitivity * SaveData.look_sensitivity)

func _apply_look(delta_pixels, sensitivity):
	yaw -= delta_pixels.x * sensitivity
	pitch -= delta_pixels.y * sensitivity
	pitch = clamp(pitch, deg_to_rad(-68.0), deg_to_rad(62.0))
	rotation.y = yaw
	head.rotation.x = pitch

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, mouse_sensitivity * SaveData.look_sensitivity)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _handle_actions():
	if Input.is_action_just_pressed("reload") or (game_hud and game_hud.consume_reload()):
		reload_weapon()
	if Input.is_action_just_pressed("knife") or (game_hud and game_hud.consume_knife()):
		knife_attack()
	if Input.is_action_just_pressed("toggle_auto") or (game_hud and game_hud.consume_auto_toggle()):
		SaveData.auto_fire = not SaveData.auto_fire
		SaveData.save_game()
		game_hud.update_auto_button()
	for i in range(4):
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			select_slot(i)
	var hud_slot = game_hud.consume_slot_request() if game_hud else -1
	if hud_slot >= 0:
		select_slot(hud_slot)
	var manual_fire = Input.is_action_pressed("fire") or (game_hud and game_hud.fire_held)
	if manual_fire:
		try_fire()

func _update_auto_fire():
	var auto_target = _find_auto_target()
	target_under_crosshair = is_instance_valid(auto_target)
	if SaveData.auto_fire and target_under_crosshair:
		try_fire(auto_target)
	if game_hud:
		game_hud.crosshair_enemy = target_under_crosshair

func _find_auto_target():
	var direct = _raycast_center(70.0)
	if not direct.is_empty():
		var direct_collider = direct.get("collider")
		if direct_collider is Combatant and direct_collider.alive and direct_collider.team != team:
			return direct_collider

	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size * 0.5
	var capture_radius = clamp(min(viewport_size.x, viewport_size.y) * 0.085, 48.0, 78.0)
	var best
	var best_distance = capture_radius
	for candidate in get_tree().get_nodes_in_group("combatants"):
		if candidate == self or not candidate.alive or candidate.team == team:
			continue
		var chest = candidate.global_position + Vector3.UP * 1.18
		if camera.is_position_behind(chest):
			continue
		var screen_pos = camera.unproject_position(chest)
		var distance = screen_pos.distance_to(screen_center)
		if distance < best_distance and _has_clear_line(candidate, chest):
			best_distance = distance
			best = candidate
	return best

func _has_clear_line(target, target_point):
	var query = PhysicsRayQueryParameters3D.create(camera.global_position, target_point)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == target

func current_stats():
	return SaveData.get_weapon_stats(current_weapon_id)

func current_state():
	return pistol_state if using_pistol else weapon_states.get(current_weapon_id, {})

func try_fire(assisted_target = null):
	if reloading or not alive or knife_animation_time > 0.0:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now < next_fire_time:
		return
	var stats = current_stats()
	var state = current_state()
	if state.is_empty():
		return
	if int(state["mag"]) <= 0:
		if int(state["reserve"]) > 0:
			reload_weapon()
		else:
			_switch_to_pistol()
		return

	next_fire_time = now + float(stats.fire_rate)
	state["mag"] = int(state["mag"]) - 1
	if using_pistol:
		pistol_state = state
	else:
		weapon_states[current_weapon_id] = state

	var any_hit = false
	var any_headshot = false
	var pellets = int(stats.pellets)
	for pellet_index in range(pellets):
		var result = _fire_pellet(stats, assisted_target)
		any_hit = any_hit or bool(result.get("hit_enemy", false))
		any_headshot = any_headshot or bool(result.get("headshot", false))
		if pellet_index < 3 and game:
			game.spawn_tracer(muzzle.global_position, result.get("endpoint", muzzle.global_position), stats.color, bool(result.get("hit_enemy", false)))

	_show_muzzle_flash(stats.color)
	recoil = min(recoil + (0.34 if pellets == 1 else 0.7), 1.0)
	pitch = clamp(pitch - (0.006 if pellets == 1 else 0.014), deg_to_rad(-68.0), deg_to_rad(62.0))
	head.rotation.x = pitch
	if game_hud:
		game_hud.on_weapon_fired(any_hit, any_headshot, float(stats.headshot_multiplier))

	if int(state["mag"]) <= 0 and int(state["reserve"]) <= 0:
		_switch_to_pistol()

func _fire_pellet(stats, assisted_target = null):
	var origin = camera.global_position
	var basis = camera.global_transform.basis
	var direction = -basis.z
	if is_instance_valid(assisted_target):
		var target_point = assisted_target.global_position + Vector3.UP * 1.16
		direction = (target_point - origin).normalized()
	var spread = float(stats.spread)
	direction += basis.x * randf_range(-spread, spread)
	direction += basis.y * randf_range(-spread, spread)
	direction = direction.normalized()
	var endpoint = origin + direction * float(stats.range)
	var query = PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	var hit_enemy = false
	var headshot = false
	if not hit.is_empty():
		endpoint = hit.get("position", endpoint)
		var collider = hit.get("collider")
		if collider is Combatant and collider.team != team:
			var damage = float(stats.damage)
			var head_height = collider.global_position.y + 1.43
			headshot = endpoint.y >= head_height
			if headshot:
				damage *= float(stats.headshot_multiplier)
			collider.take_damage(damage, self)
			hit_enemy = true
	return {"endpoint": endpoint, "hit_enemy": hit_enemy, "headshot": headshot}

func _raycast_center(distance):
	var origin = camera.global_position
	var query = PhysicsRayQueryParameters3D.create(origin, origin + (-camera.global_transform.basis.z) * distance)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func reload_weapon():
	if reloading:
		return
	var state = current_state()
	var stats = current_stats()
	if state.is_empty() or int(state["mag"]) >= int(stats.magazine) or int(state["reserve"]) <= 0:
		return
	reloading = true
	if game_hud:
		game_hud.show_center_message("ПЕРЕЗАРЯДКА")
	await get_tree().create_timer(1.25 if current_weapon_id != "shotgun" else 1.55).timeout
	if not alive:
		reloading = false
		return
	var needed = int(stats.magazine) - int(state["mag"])
	var loaded = min(needed, int(state["reserve"]))
	state["mag"] = int(state["mag"]) + loaded
	state["reserve"] = int(state["reserve"]) - loaded
	if using_pistol:
		pistol_state = state
	else:
		weapon_states[current_weapon_id] = state
	reloading = false

func knife_attack():
	var now = Time.get_ticks_msec() / 1000.0
	if now < knife_ready_time or not alive:
		return
	knife_ready_time = now + 0.9
	knife_animation_time = knife_animation_duration
	if game_hud:
		game_hud.flash_knife()
	await get_tree().create_timer(0.11).timeout
	if not alive:
		return
	var hit = _raycast_center(2.35)
	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider is Combatant and collider.team != team:
			collider.take_damage(55.0, self)
			if game_hud:
				game_hud.on_weapon_fired(true, false, 1.0)

func select_slot(index):
	if index < 0 or index >= SaveData.loadout.size():
		return
	var id = SaveData.loadout[index]
	if id == "":
		return
	current_slot = index
	current_weapon_id = id
	using_pistol = false
	reloading = false
	_update_weapon_model()

func _switch_to_pistol():
	if using_pistol:
		if game_hud:
			game_hud.show_center_message("НЕТ ПАТРОНОВ")
		return
	using_pistol = true
	current_weapon_id = "pistol"
	reloading = false
	_update_weapon_model()
	if game_hud:
		game_hud.show_center_message("ПИСТОЛЕТ")


func _build_knife_model():
	knife_root = Node3D.new()
	knife_root.visible = false
	camera.add_child(knife_root)
	_add_knife_box(Vector3(0.0, -0.03, 0.0), Vector3(0.13, 0.18, 0.46), Color("20262d"), Vector3(-8, 0, 0))
	_add_knife_box(Vector3(0.0, 0.0, -0.34), Vector3(0.075, 0.055, 0.52), Color("dce8ef"), Vector3(0, 0, 0))
	_add_knife_box(Vector3(0.0, 0.0, -0.62), Vector3(0.02, 0.045, 0.18), Color("f5fbff"), Vector3(0, 0, 0))

func _add_knife_box(pos, box_size, color, rotation_deg = Vector3.ZERO):
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rotation_deg
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.62
	mat.roughness = 0.24
	mesh_instance.material_override = mat
	knife_root.add_child(mesh_instance)

func _update_knife_animation(delta):
	if not is_instance_valid(knife_root):
		return
	if knife_animation_time <= 0.0:
		knife_root.visible = false
		if is_instance_valid(weapon_root):
			weapon_root.visible = true
		return
	knife_animation_time = max(0.0, knife_animation_time - delta)
	var progress = 1.0 - knife_animation_time / knife_animation_duration
	var start_pos = Vector3(0.58, -0.58, -0.24)
	var strike_pos = Vector3(0.04, -0.12, -0.86)
	var end_pos = Vector3(0.48, -0.52, -0.34)
	var start_rot = Vector3(-22.0, -28.0, 28.0)
	var strike_rot = Vector3(10.0, 18.0, -58.0)
	var end_rot = Vector3(-18.0, -20.0, 18.0)
	var phase = 0.0
	if progress < 0.42:
		phase = ease(progress / 0.42, -2.2)
		knife_root.position = start_pos.lerp(strike_pos, phase)
		knife_root.rotation_degrees = start_rot.lerp(strike_rot, phase)
	else:
		phase = ease((progress - 0.42) / 0.58, 2.2)
		knife_root.position = strike_pos.lerp(end_pos, phase)
		knife_root.rotation_degrees = strike_rot.lerp(end_rot, phase)
	knife_root.visible = true
	if is_instance_valid(weapon_root):
		weapon_root.visible = false

func _update_weapon_model():
	if not is_instance_valid(weapon_root):
		return
	for child in weapon_root.get_children():
		weapon_root.remove_child(child)
		child.free()

	var stats = SaveData.get_weapon_stats(current_weapon_id)
	var body_color = stats.get("color", Color.WHITE)
	weapon_root.position = Vector3(0.34, -0.31, -0.58)
	weapon_root.rotation_degrees = Vector3(-3.0, 0.0, 0.0)

	if current_weapon_id == "shotgun":
		_add_weapon_box(Vector3(0, 0, -0.12), Vector3(0.19, 0.17, 0.7), body_color)
		_add_weapon_box(Vector3(0, 0.015, -0.59), Vector3(0.09, 0.09, 0.42), Color("2b3038"))
		_add_weapon_box(Vector3(0, -0.15, 0.0), Vector3(0.12, 0.28, 0.16), Color("20262d"), Vector3(-12, 0, 0))
		_add_weapon_box(Vector3(0, -0.04, 0.34), Vector3(0.16, 0.15, 0.28), Color("5d3b24"))
		_create_muzzle(Vector3(0, 0.015, -0.83))
	elif current_weapon_id == "pistol":
		_add_weapon_box(Vector3(0, 0, -0.1), Vector3(0.16, 0.18, 0.42), body_color)
		_add_weapon_box(Vector3(0, -0.18, 0.02), Vector3(0.13, 0.32, 0.16), Color("20262d"), Vector3(-10, 0, 0))
		_add_weapon_box(Vector3(0, 0.035, -0.38), Vector3(0.08, 0.07, 0.18), Color("2b3038"))
		_create_muzzle(Vector3(0, 0.035, -0.5))
	else:
		_add_weapon_box(Vector3(0, 0, -0.12), Vector3(0.19, 0.18, 0.62), body_color)
		_add_weapon_box(Vector3(0, 0.025, -0.55), Vector3(0.075, 0.075, 0.36), Color("2b3038"))
		_add_weapon_box(Vector3(0, -0.2, -0.08), Vector3(0.13, 0.36, 0.17), Color("20262d"), Vector3(-12, 0, 0))
		_add_weapon_box(Vector3(0, -0.13, 0.24), Vector3(0.16, 0.24, 0.24), Color("313a45"), Vector3(10, 0, 0))
		_add_weapon_box(Vector3(0, 0.13, -0.18), Vector3(0.08, 0.08, 0.22), Color("151a20"))
		_create_muzzle(Vector3(0, 0.025, -0.77))

func _add_weapon_box(pos, box_size, color, rotation_deg = Vector3.ZERO):
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rotation_deg
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.38
	mat.roughness = 0.3
	mesh_instance.material_override = mat
	weapon_root.add_child(mesh_instance)

func _create_muzzle(pos):
	muzzle = Node3D.new()
	muzzle.position = pos
	weapon_root.add_child(muzzle)
	muzzle_flash = MeshInstance3D.new()
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 0.075
	flash_mesh.height = 0.15
	muzzle_flash.mesh = flash_mesh
	var flash_mat = StandardMaterial3D.new()
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.albedo_color = Color("fff1a8")
	flash_mat.emission_enabled = true
	flash_mat.emission = Color("ff9f1c")
	muzzle_flash.material_override = flash_mat
	muzzle_flash.visible = false
	muzzle.add_child(muzzle_flash)
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color("ffb347")
	muzzle_light.light_energy = 1.8
	muzzle_light.omni_range = 2.5
	muzzle_light.shadow_enabled = false
	muzzle_light.visible = false
	muzzle.add_child(muzzle_light)

func _show_muzzle_flash(color):
	muzzle_flash_time = 0.055
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = true
		muzzle_flash.scale = Vector3.ONE * randf_range(0.8, 1.25)
		var mat = muzzle_flash.material_override
		if mat:
			mat.emission = color.lerp(Color("fff1a8"), 0.65)
	if is_instance_valid(muzzle_light):
		muzzle_light.visible = true

func _update_weapon_visuals(delta):
	_update_knife_animation(delta)
	recoil = move_toward(recoil, 0.0, delta * 5.2)
	if is_instance_valid(weapon_root):
		var move_amount = Vector2(velocity.x, velocity.z).length() / speed if alive else 0.0
		var sway_x = sin(bob_time * 0.5) * 0.012 * move_amount
		var sway_y = abs(cos(bob_time)) * 0.012 * move_amount
		var target_pos = Vector3(0.34 + sway_x, -0.31 - sway_y - recoil * 0.055, -0.58 + recoil * 0.09)
		weapon_root.position = weapon_root.position.lerp(target_pos, min(1.0, delta * 18.0))
	if muzzle_flash_time > 0.0:
		muzzle_flash_time -= delta
	else:
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
		if is_instance_valid(muzzle_light):
			muzzle_light.visible = false

func on_health_changed():
	if game_hud:
		game_hud.damage_flash = 0.35
		if health <= 0.0:
			game_hud.release_controls()

func on_respawned():
	knife_animation_time = 0.0
	if is_instance_valid(knife_root):
		knife_root.visible = false
	if is_instance_valid(weapon_root):
		weapon_root.visible = true
	_reset_ammo()
	look_accumulator = Vector2.ZERO
	_face_towards(Vector3.ZERO)
	if game_hud:
		game_hud.release_controls()
		game_hud.show_center_message("В БОЙ!")

func ammo_text():
	var state = current_state()
	if state.is_empty():
		return "0 / 0"
	return "%d / %d" % [int(state["mag"]), int(state["reserve"])]

func weapon_display_name():
	var stats = SaveData.get_weapon_stats(current_weapon_id)
	if current_weapon_id == "pistol":
		return stats.get("name", "Оружие")
	return "%s • ур.%d • мощь %d" % [stats.get("name", "Оружие"), int(stats.level), int(stats.power)]
