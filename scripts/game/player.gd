extends Combatant
class_name PlayerCombatant

var camera
var head
var weapon_mesh
var game_hud
var yaw = 0.0
var pitch = 0.0
var speed = 7.0
var sensitivity = 0.0025
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
	head.position.y = 1.58
	add_child(head)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 76.0
	head.add_child(camera)
	weapon_mesh = MeshInstance3D.new()
	camera.add_child(weapon_mesh)
	weapon_mesh.position = Vector3(0.38, -0.28, -0.72)
	weapon_mesh.rotation_degrees = Vector3(-4, 178, 0)
	_update_weapon_model()

func setup_player(p_game, p_team, p_name, p_spawn, hud):
	setup(p_game, p_team, p_name, p_spawn)
	game_hud = hud
	if not is_node_ready():
		await ready
	game_hud.set_player(self)

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
		return
	_handle_look(delta)
	_handle_move(delta)
	_handle_actions()
	_update_auto_fire()
	_recover_recoil(delta)

func _handle_move(delta):
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if game_hud:
		input_vec += game_hud.move_vector
		if input_vec.length() > 1.0:
			input_vec = input_vec.normalized()
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	var direction = (right * input_vec.x + forward * input_vec.y)
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 7.0 * delta)
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()

func _handle_look(_delta):
	var look_delta = Vector2.ZERO
	if game_hud:
		look_delta += game_hud.consume_look_delta()
	if look_delta != Vector2.ZERO:
		yaw -= look_delta.x * sensitivity * 1.3
		pitch -= look_delta.y * sensitivity * 1.3
		pitch = clamp(pitch, -1.15, 1.05)
		rotation.y = yaw
		head.rotation.x = pitch

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch = clamp(pitch, -1.15, 1.05)
		rotation.y = yaw
		head.rotation.x = pitch
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
	target_under_crosshair = _crosshair_has_enemy()
	if SaveData.auto_fire and target_under_crosshair:
		try_fire()
	if game_hud:
		game_hud.crosshair_enemy = target_under_crosshair

func _crosshair_has_enemy():
	var result = _raycast_center(65.0)
	if result.is_empty():
		return false
	var collider = result.get("collider")
	return collider is Combatant and collider.alive and collider.team != team

func current_stats():
	return SaveData.get_weapon_stats(current_weapon_id)

func current_state():
	return pistol_state if using_pistol else weapon_states.get(current_weapon_id, {})

func try_fire():
	if reloading or not alive:
		return
	var now = Time.get_ticks_msec() / 1000.0
	if now < next_fire_time:
		return
	var stats = current_stats()
	var state = current_state()
	if state.is_empty():
		return
	if int(state.mag) <= 0:
		if int(state.reserve) > 0:
			reload_weapon()
		else:
			_switch_to_pistol()
		return
	next_fire_time = now + float(stats.fire_rate)
	state.mag -= 1
	if using_pistol:
		pistol_state = state
	else:
		weapon_states[current_weapon_id] = state
	var pellets = int(stats.pellets)
	for _i in range(pellets):
		_fire_pellet(stats)
	recoil = min(recoil + (0.045 if pellets == 1 else 0.11), 0.22)
	pitch = clamp(pitch - recoil * 0.18, -1.15, 1.05)
	head.rotation.x = pitch
	_update_weapon_pose()
	if int(state.mag) <= 0 and int(state.reserve) <= 0:
		_switch_to_pistol()

func _fire_pellet(stats):
	var origin = camera.global_position
	var basis = camera.global_transform.basis
	var direction = -basis.z
	var spread = float(stats.spread)
	direction += basis.x * randf_range(-spread, spread)
	direction += basis.y * randf_range(-spread, spread)
	direction = direction.normalized()
	var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * float(stats.range))
	query.collision_mask = 3
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider = hit.get("collider")
	if collider is Combatant and collider.team != team:
		collider.take_damage(float(stats.damage), self)

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
	if state.is_empty() or int(state.mag) >= int(stats.magazine) or int(state.reserve) <= 0:
		return
	reloading = true
	if game_hud:
		game_hud.show_center_message("ПЕРЕЗАРЯДКА")
	await get_tree().create_timer(1.25 if current_weapon_id != "shotgun" else 1.55).timeout
	if not alive:
		reloading = false
		return
	var needed = int(stats.magazine) - int(state.mag)
	var loaded = min(needed, int(state.reserve))
	state.mag += loaded
	state.reserve -= loaded
	if using_pistol:
		pistol_state = state
	else:
		weapon_states[current_weapon_id] = state
	reloading = false

func knife_attack():
	var now = Time.get_ticks_msec() / 1000.0
	if now < knife_ready_time:
		return
	knife_ready_time = now + 0.9
	var hit = _raycast_center(2.25)
	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider is Combatant and collider.team != team:
			collider.take_damage(55.0, self)
	if game_hud:
		game_hud.flash_knife()

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
		return
	using_pistol = true
	current_weapon_id = "pistol"
	reloading = false
	_update_weapon_model()
	if game_hud:
		game_hud.show_center_message("ПИСТОЛЕТ")

func _update_weapon_model():
	if not is_instance_valid(weapon_mesh):
		return
	var stats = SaveData.get_weapon_stats(current_weapon_id)
	var mesh = BoxMesh.new()
	if current_weapon_id == "shotgun":
		mesh.size = Vector3(0.18, 0.16, 0.95)
	elif current_weapon_id == "pistol":
		mesh.size = Vector3(0.16, 0.22, 0.42)
	else:
		mesh.size = Vector3(0.19, 0.18, 0.78)
	weapon_mesh.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = stats.get("color", Color.WHITE)
	mat.metallic = 0.35
	mat.roughness = 0.32
	weapon_mesh.material_override = mat
	_update_weapon_pose()

func _update_weapon_pose():
	if weapon_mesh:
		weapon_mesh.position = Vector3(0.38, -0.28 - recoil * 0.25, -0.72 + recoil * 0.4)

func _recover_recoil(delta):
	recoil = move_toward(recoil, 0.0, delta * 0.8)
	_update_weapon_pose()

func on_health_changed():
	if game_hud:
		game_hud.damage_flash = 0.35

func on_respawned():
	_reset_ammo()
	pitch = 0.0
	head.rotation.x = 0.0
	if game_hud:
		game_hud.show_center_message("В БОЙ!")

func ammo_text():
	var state = current_state()
	if state.is_empty():
		return "0 / 0"
	return "%d / %d" % [int(state.mag), int(state.reserve)]

func weapon_display_name():
	return SaveData.get_weapon_stats(current_weapon_id).get("name", "Оружие")
