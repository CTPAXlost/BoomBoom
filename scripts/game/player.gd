extends "res://scripts/game/combatant.gd"
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
var speed = 5.6
var acceleration = 18.0
var deceleration = 23.0
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
var reload_token = 0
var reload_animation_time = 0.0
var reload_animation_duration = 0.0
var knife_ready_time = 0.0
var target_under_crosshair = false
var target_out_of_range = false
var tracked_target
var tracked_distance = -1.0
var recoil = 0.0
var muzzle_flash_time = 0.0
var bob_time = 0.0
var knife_animation_time = 0.0
var knife_animation_duration = 0.42
var aiming = false
var range_message_ready = 0.0
var medkits_used_life = 0
var grenades_used_life = 0
var grenade_ready_time = 0.0
var soft_aim_target
var shot_audio
var reload_audio
var knife_audio
var footstep_audio
var footstep_timer = 0.0
var footstep_index = 0

const FOOTSTEP_SOUND_PATHS = [
	"res://assets/audio/footstep1.wav",
	"res://assets/audio/footstep2.wav"
]
const RELOAD_SOUND_PATH = "res://assets/audio/reload.wav"
const KNIFE_SOUND_PATH = "res://assets/audio/knife.wav"

func _load_audio(path):
	if path == null or str(path).is_empty():
		return null
	return ResourceLoader.load(str(path), "AudioStream", ResourceLoader.CACHE_MODE_REUSE)

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
	shot_audio = AudioStreamPlayer3D.new()
	shot_audio.max_distance = 42.0
	shot_audio.unit_size = 4.0
	add_child(shot_audio)
	reload_audio = AudioStreamPlayer3D.new()
	reload_audio.stream = _load_audio(RELOAD_SOUND_PATH)
	reload_audio.max_distance = 24.0
	add_child(reload_audio)
	knife_audio = AudioStreamPlayer3D.new()
	knife_audio.stream = _load_audio(KNIFE_SOUND_PATH)
	knife_audio.max_distance = 12.0
	add_child(knife_audio)
	footstep_audio = AudioStreamPlayer3D.new()
	footstep_audio.max_distance = 13.0
	footstep_audio.volume_db = -7.0
	add_child(footstep_audio)
	_build_knife_model()
	_update_weapon_model()

func setup_player(p_game, p_team, p_name, p_spawn, hud):
	setup(p_game, p_team, p_name, p_spawn)
	game_hud = hud
	if not is_node_ready():
		await ready
	max_health = float(SaveData.player_max_health())
	health = max_health
	set_armor_capacity(SaveData.armor_capacity())
	headshot_damage_multiplier = 0.5 if SaveData.helmet_owned else 1.0
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
	for id in SaveData.main_weapon_ids():
		var stats = SaveData.get_weapon_stats(id)
		weapon_states[id] = {"mag": int(stats.magazine), "reserve": int(stats.reserve)}
	var pistol = SaveData.get_weapon_stats("pistol")
	pistol_state = {"mag": int(pistol.magazine), "reserve": int(pistol.reserve)}
	using_pistol = false
	medkits_used_life = 0
	grenades_used_life = 0
	reloading = false
	reload_token += 1
	reload_animation_time = 0.0
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
	_handle_weapon_selection()
	if is_instance_valid(game) and game.combat_enabled:
		_apply_soft_aim(delta)
		_handle_move(delta)
		_handle_actions()
		_update_targeting_and_auto_fire()
	else:
		velocity = Vector3.ZERO
		tracked_target = null
		target_under_crosshair = false
		target_out_of_range = false
		tracked_distance = -1.0
		if game_hud:
			game_hud.update_distance(-1.0, float(current_stats().range), false, false)
	_update_weapon_visuals(delta)

func _handle_weapon_selection():
	for i in range(4):
		if Input.is_action_just_pressed("slot_%d" % (i + 1)):
			select_slot(i)
	var hud_slot = game_hud.consume_slot_request() if game_hud else -1
	if hud_slot >= 0:
		select_slot(hud_slot)

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
	_update_footsteps(delta, moving)
	var bob = sin(bob_time) * 0.022 if moving else 0.0
	head.position.y = lerp(head.position.y, 1.62 + bob, min(1.0, delta * 12.0))

func _update_footsteps(delta, moving):
	if not moving:
		footstep_timer = min(footstep_timer, 0.18)
		return
	footstep_timer -= delta
	if footstep_timer <= 0.0 and is_instance_valid(footstep_audio):
		footstep_audio.stream = _load_audio(FOOTSTEP_SOUND_PATHS[footstep_index % FOOTSTEP_SOUND_PATHS.size()])
		footstep_index += 1
		footstep_audio.pitch_scale = randf_range(0.95, 1.05)
		footstep_audio.play()
		footstep_timer = 0.48

func _handle_look(delta):
	if game_hud:
		look_accumulator += game_hud.consume_look_delta()
	var smoothing = 1.0 - exp(-24.0 * delta)
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

func _apply_soft_aim(delta):
	if not SaveData.aim_assist or reloading or knife_animation_time > 0.0:
		soft_aim_target = null
		return
	soft_aim_target = _find_aim_assist_candidate()
	if not is_instance_valid(soft_aim_target):
		return
	var target_point = soft_aim_target.global_position + Vector3.UP * 1.2
	var direction = (target_point - camera.global_position).normalized()
	var desired_yaw = atan2(-direction.x, -direction.z)
	var desired_pitch = -asin(clamp(direction.y, -1.0, 1.0))
	var strength = 0.42
	if aiming:
		strength = 0.9
	elif game_hud and game_hud.fire_held:
		strength = 0.68
	var blend = clamp(delta * strength, 0.0, 0.075)
	yaw = lerp_angle(yaw, desired_yaw, blend)
	pitch = lerp_angle(pitch, desired_pitch, blend)
	pitch = clamp(pitch, deg_to_rad(-68.0), deg_to_rad(62.0))
	rotation.y = yaw
	head.rotation.x = pitch

func _find_aim_assist_candidate():
	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size * 0.5
	var capture_radius = clamp(min(viewport_size.x, viewport_size.y) * (0.12 if aiming else 0.15), 72.0, 132.0)
	var best
	var best_score = capture_radius
	var stats = current_stats()
	for candidate in get_tree().get_nodes_in_group("combatants"):
		if candidate == self or not candidate.alive or candidate.team == team:
			continue
		var target_point = candidate.global_position + Vector3.UP * 1.18
		if camera.is_position_behind(target_point):
			continue
		if global_position.distance_to(candidate.global_position) > float(stats.range) * 1.08:
			continue
		var screen_pos = camera.unproject_position(target_point)
		var screen_distance = screen_pos.distance_to(screen_center)
		if screen_distance < best_score and _has_clear_line(candidate, target_point):
			best_score = screen_distance
			best = candidate
	return best

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_look(event.relative, mouse_sensitivity * SaveData.look_sensitivity)
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _handle_actions():
	aiming = Input.is_action_pressed("aim") or (game_hud and game_hud.aim_held)
	if Input.is_action_just_pressed("reload") or (game_hud and game_hud.consume_reload()):
		reload_weapon()
	if Input.is_action_just_pressed("knife") or (game_hud and game_hud.consume_knife()):
		knife_attack()
	if Input.is_action_just_pressed("medkit") or (game_hud and game_hud.consume_medkit()):
		use_medkit()
	if Input.is_action_just_pressed("grenade") or (game_hud and game_hud.consume_grenade()):
		throw_grenade()
	if Input.is_action_just_pressed("toggle_auto") or (game_hud and game_hud.consume_auto_toggle()):
		SaveData.auto_fire = not SaveData.auto_fire
		SaveData.save_game()
		game_hud.update_auto_button()
	var manual_fire = Input.is_action_pressed("fire") or (game_hud and game_hud.fire_held)
	if manual_fire:
		try_fire()

func _update_targeting_and_auto_fire():
	tracked_target = _find_crosshair_target()
	target_under_crosshair = false
	target_out_of_range = false
	tracked_distance = -1.0
	var stats = current_stats()
	if is_instance_valid(tracked_target):
		tracked_distance = global_position.distance_to(tracked_target.global_position)
		if tracked_distance <= float(stats.range):
			target_under_crosshair = true
		else:
			target_out_of_range = true
	if SaveData.auto_fire and target_under_crosshair:
		try_fire(tracked_target)
	if game_hud:
		game_hud.crosshair_enemy = target_under_crosshair
		game_hud.crosshair_out_of_range = target_out_of_range
		game_hud.update_distance(tracked_distance, float(stats.range), is_instance_valid(tracked_target), target_under_crosshair)

func _find_crosshair_target():
	var direct = _raycast_center(80.0)
	if not direct.is_empty():
		var direct_collider = direct.get("collider")
		if direct_collider is Node and direct_collider.is_in_group("combatants") and direct_collider.alive and direct_collider.team != team:
			return direct_collider

	var viewport_size = get_viewport().get_visible_rect().size
	var screen_center = viewport_size * 0.5
	var radius_ratio = 0.055 if aiming else 0.085
	var capture_radius = clamp(min(viewport_size.x, viewport_size.y) * radius_ratio, 42.0, 78.0)
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
	if reloading or not alive or knife_animation_time > 0.0 or not is_instance_valid(game) or not game.combat_enabled:
		return
	var now = Time.get_ticks_msec() * 0.001
	if now < next_fire_time:
		return
	var stats = current_stats()
	if is_instance_valid(assisted_target):
		var assisted_distance = global_position.distance_to(assisted_target.global_position)
		if assisted_distance > float(stats.range):
			_show_out_of_range_message(now, stats)
			return
	elif is_instance_valid(tracked_target) and target_out_of_range:
		_show_out_of_range_message(now, stats)
		return

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
	_play_weapon_sound(stats)

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
	recoil = min(recoil + float(stats.get("recoil_visual", 0.35)), 1.25)
	var aim_recoil_multiplier = 0.72 if aiming else 1.0
	pitch = clamp(pitch - float(stats.get("recoil_pitch", 0.007)) * aim_recoil_multiplier, deg_to_rad(-68.0), deg_to_rad(62.0))
	yaw += randf_range(-float(stats.get("recoil_yaw", 0.003)), float(stats.get("recoil_yaw", 0.003))) * aim_recoil_multiplier
	rotation.y = yaw
	head.rotation.x = pitch
	if game_hud:
		game_hud.on_weapon_fired(any_hit, any_headshot, float(stats.headshot_multiplier))

	if int(state["mag"]) <= 0:
		if int(state["reserve"]) > 0:
			reload_weapon()
		else:
			_switch_to_pistol()

func _play_weapon_sound(stats):
	if not is_instance_valid(shot_audio):
		return
	var path = str(stats.get("sound", ""))
	if path.is_empty():
		return
	shot_audio.stream = _load_audio(path)
	shot_audio.pitch_scale = randf_range(0.97, 1.035)
	shot_audio.play()

func _show_out_of_range_message(now, stats):
	if now < range_message_ready:
		return
	range_message_ready = now + 0.7
	if game_hud:
		game_hud.show_center_message("ВНЕ ДАЛЬНОСТИ • %d ШАГОВ" % int(stats.range), 0.65)

func _fire_pellet(stats, assisted_target = null):
	var origin = camera.global_position
	var basis = camera.global_transform.basis
	var direction = -basis.z
	if is_instance_valid(assisted_target):
		var target_point = assisted_target.global_position + Vector3.UP * 1.16
		direction = (target_point - origin).normalized()
	var spread = float(stats.spread)
	if aiming:
		spread *= float(stats.get("aim_spread_multiplier", 0.5))
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
		if collider is Node and collider.is_in_group("combatants") and collider.team != team:
			var damage = float(stats.damage)
			var hit_distance = origin.distance_to(endpoint)
			if current_weapon_id == "shotgun":
				var distance_ratio = clamp(hit_distance / max(float(stats.range), 0.01), 0.0, 1.0)
				damage *= lerp(1.0, 0.25, distance_ratio)
			var head_height = collider.global_position.y + 1.43
			headshot = endpoint.y >= head_height
			if headshot:
				damage *= float(stats.headshot_multiplier)
			collider.take_damage(damage, self, {"method": current_weapon_id, "headshot": headshot})
			hit_enemy = true
	return {"endpoint": endpoint, "hit_enemy": hit_enemy, "headshot": headshot}

func _raycast_center(distance):
	var origin = camera.global_position
	var query = PhysicsRayQueryParameters3D.create(origin, origin + (-camera.global_transform.basis.z) * distance)
	query.collision_mask = 3
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func reload_weapon():
	if reloading or not alive:
		return
	var state = current_state()
	var stats = current_stats()
	if state.is_empty() or int(state["mag"]) >= int(stats.magazine) or int(state["reserve"]) <= 0:
		return
	reloading = true
	reload_token += 1
	var token = reload_token
	var reload_weapon_id = current_weapon_id
	var reload_pistol = using_pistol
	reload_animation_duration = float(stats.get("reload_time", 2.0))
	reload_animation_time = reload_animation_duration
	if is_instance_valid(reload_audio):
		reload_audio.pitch_scale = clamp(2.4 / max(reload_animation_duration, 0.2), 0.62, 1.35)
		reload_audio.play()
	if game_hud:
		game_hud.show_center_message("ПЕРЕЗАРЯДКА", min(1.0, reload_animation_duration))
	await get_tree().create_timer(reload_animation_duration).timeout
	if token != reload_token or not alive:
		return
	var final_state = pistol_state if reload_pistol else weapon_states.get(reload_weapon_id, {})
	var final_stats = SaveData.get_weapon_stats(reload_weapon_id)
	if final_state.is_empty():
		reloading = false
		reload_animation_time = 0.0
		return
	var needed = int(final_stats.magazine) - int(final_state["mag"])
	var loaded = min(needed, int(final_state["reserve"]))
	final_state["mag"] = int(final_state["mag"]) + loaded
	final_state["reserve"] = int(final_state["reserve"]) - loaded
	if reload_pistol:
		pistol_state = final_state
	else:
		weapon_states[reload_weapon_id] = final_state
	reloading = false
	reload_animation_time = 0.0

func knife_attack():
	var now = Time.get_ticks_msec() * 0.001
	if now < knife_ready_time or not alive or not is_instance_valid(game) or not game.combat_enabled:
		return
	knife_ready_time = now + 0.9
	reload_token += 1
	reloading = false
	reload_animation_time = 0.0
	knife_animation_time = knife_animation_duration
	if is_instance_valid(knife_audio):
		knife_audio.pitch_scale = randf_range(0.96, 1.04)
		knife_audio.play()
	if game_hud:
		game_hud.flash_knife()
	await get_tree().create_timer(0.11).timeout
	if not alive:
		return
	var hit = _raycast_center(2.35)
	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider is Node and collider.is_in_group("combatants") and collider.team != team:
			collider.take_damage(55.0, self, {"method": "knife", "headshot": false})
			if game_hud:
				game_hud.on_weapon_fired(true, false, 1.0)

func use_medkit():
	if not alive or not is_instance_valid(game) or not game.combat_enabled:
		return
	if medkits_used_life >= SaveData.MEDKIT_PER_LIFE:
		if game_hud:
			game_hud.show_center_message("ЛИМИТ: 10 АПТЕЧЕК ЗА ЖИЗНЬ", 0.9)
		return
	if health >= max_health:
		if game_hud:
			game_hud.show_center_message("ЗДОРОВЬЕ ПОЛНОЕ", 0.65)
		return
	if not SaveData.consume_medkit():
		if game_hud:
			game_hud.show_center_message("АПТЕЧКИ ЗАКОНЧИЛИСЬ", 0.9)
		return
	medkits_used_life += 1
	health = min(max_health, health + SaveData.MEDKIT_HEAL)
	on_health_changed()
	if game_hud:
		game_hud.show_center_message("+%d HP • АПТЕЧЕК %d" % [SaveData.MEDKIT_HEAL, SaveData.medkits], 0.8)

func throw_grenade():
	var now = Time.get_ticks_msec() * 0.001
	if not alive or now < grenade_ready_time or not is_instance_valid(game) or not game.combat_enabled:
		return
	if grenades_used_life >= SaveData.GRENADE_PER_LIFE:
		if game_hud:
			game_hud.show_center_message("ЛИМИТ: 2 ГРАНАТЫ ЗА ЖИЗНЬ", 0.9)
		return
	if not SaveData.consume_grenade():
		if game_hud:
			game_hud.show_center_message("ГРАНАТЫ ЗАКОНЧИЛИСЬ", 0.9)
		return
	grenades_used_life += 1
	grenade_ready_time = now + 1.25
	var origin = camera.global_position + (-camera.global_transform.basis.z) * 0.65 + Vector3.DOWN * 0.18
	var direction = -camera.global_transform.basis.z
	game.throw_grenade(self, origin, direction)
	if game_hud:
		game_hud.show_center_message("ГРАНАТА! • ОСТАЛОСЬ %d" % SaveData.grenades, 0.7)

func consumable_text():
	return {
		"medkits": SaveData.medkits,
		"medkits_life": SaveData.MEDKIT_PER_LIFE - medkits_used_life,
		"grenades": SaveData.grenades,
		"grenades_life": SaveData.GRENADE_PER_LIFE - grenades_used_life
	}

func select_slot(index):
	if index < 0 or index >= SaveData.loadout.size():
		return
	var id = SaveData.loadout[index]
	if id == "":
		return
	current_slot = index
	current_weapon_id = id
	using_pistol = false
	reload_token += 1
	reloading = false
	reload_animation_time = 0.0
	_update_weapon_model()

func _switch_to_pistol():
	if using_pistol:
		if game_hud:
			game_hud.show_center_message("НЕТ ПАТРОНОВ")
		return
	using_pistol = true
	current_weapon_id = "pistol"
	reload_token += 1
	reloading = false
	reload_animation_time = 0.0
	_update_weapon_model()
	if game_hud:
		game_hud.show_center_message("ПИСТОЛЕТ")

func _build_knife_model():
	knife_root = Node3D.new()
	knife_root.visible = false
	camera.add_child(knife_root)
	_add_knife_box(Vector3(0.02, -0.02, 0.08), Vector3(0.18, 0.2, 0.5), Color("20262d"), Vector3(-8, 0, 0))
	_add_knife_box(Vector3(0.0, 0.0, -0.25), Vector3(0.26, 0.07, 0.08), Color("d9b35f"))
	_add_knife_box(Vector3(0.0, 0.015, -0.58), Vector3(0.095, 0.055, 0.62), Color("dce8ef"), Vector3(0, 0, -2))
	_add_knife_box(Vector3(0.035, 0.018, -0.91), Vector3(0.025, 0.045, 0.18), Color("f7fbff"), Vector3(0, 7, 0))
	_add_knife_box(Vector3(0.1, -0.12, 0.1), Vector3(0.2, 0.16, 0.28), Color("b97855"), Vector3(-20, 0, 10))

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

	if current_weapon_id == "sniper":
		_add_weapon_box(Vector3(0, 0, -0.1), Vector3(0.16, 0.15, 0.86), body_color)
		_add_weapon_box(Vector3(0, 0.01, -0.76), Vector3(0.07, 0.07, 0.76), Color("20262d"))
		_add_weapon_cylinder(Vector3(0, 0.16, -0.25), 0.075, 0.5, Color("151a20"), Vector3(90, 0, 0))
		_add_weapon_box(Vector3(0, -0.18, 0.04), Vector3(0.12, 0.34, 0.18), Color("4d3324"), Vector3(-12, 0, 0))
		_add_weapon_box(Vector3(0, -0.02, 0.38), Vector3(0.19, 0.18, 0.34), Color("5d3b24"), Vector3(2, 0, 0))
		_add_weapon_box(Vector3(0, -0.12, -0.34), Vector3(0.08, 0.28, 0.1), Color("1c2229"), Vector3(-10, 0, 0))
		_create_muzzle(Vector3(0, 0.01, -1.17))
	elif current_weapon_id == "shotgun":
		_add_weapon_box(Vector3(0, 0, -0.12), Vector3(0.19, 0.17, 0.7), body_color)
		_add_weapon_box(Vector3(0, 0.015, -0.59), Vector3(0.09, 0.09, 0.42), Color("2b3038"))
		_add_weapon_box(Vector3(0, -0.15, 0.0), Vector3(0.12, 0.28, 0.16), Color("20262d"), Vector3(-12, 0, 0))
		_add_weapon_box(Vector3(0, -0.04, 0.34), Vector3(0.16, 0.15, 0.28), Color("5d3b24"))
		_create_muzzle(Vector3(0, 0.015, -0.83))
	elif current_weapon_id == "machinegun":
		_add_weapon_box(Vector3(0, 0, -0.08), Vector3(0.24, 0.22, 0.78), body_color)
		_add_weapon_box(Vector3(0, 0.02, -0.62), Vector3(0.1, 0.1, 0.55), Color("252b33"))
		_add_weapon_box(Vector3(0, -0.22, 0.02), Vector3(0.15, 0.38, 0.2), Color("20262d"), Vector3(-10, 0, 0))
		_add_weapon_box(Vector3(0.0, -0.16, 0.29), Vector3(0.24, 0.32, 0.28), Color("333b45"), Vector3(8, 0, 0))
		_add_weapon_box(Vector3(0, 0.14, -0.24), Vector3(0.1, 0.09, 0.32), Color("171b22"))
		_create_muzzle(Vector3(0, 0.02, -0.92))
	elif current_weapon_id == "pistol":
		_add_weapon_box(Vector3(0, 0, -0.1), Vector3(0.16, 0.18, 0.42), body_color)
		_add_weapon_box(Vector3(0, -0.18, 0.02), Vector3(0.13, 0.32, 0.16), Color("20262d"), Vector3(-10, 0, 0))
		_add_weapon_box(Vector3(0, 0.035, -0.38), Vector3(0.08, 0.07, 0.18), Color("2b3038"))
		_create_muzzle(Vector3(0, 0.035, -0.5))
	else:
		var body_length = 0.62
		var barrel_length = 0.36
		var mag_size = Vector3(0.16, 0.24, 0.24)
		if current_weapon_id == "rifle_vortex":
			body_length = 0.69
			barrel_length = 0.31
			mag_size = Vector3(0.15, 0.29, 0.22)
		elif current_weapon_id == "rifle_bastion":
			body_length = 0.72
			barrel_length = 0.42
			mag_size = Vector3(0.18, 0.22, 0.28)
		elif current_weapon_id == "rifle_phoenix":
			body_length = 0.78
			barrel_length = 0.4
			mag_size = Vector3(0.16, 0.31, 0.25)
		_add_weapon_box(Vector3(0, 0, -0.12), Vector3(0.19, 0.18, body_length), body_color)
		_add_weapon_box(Vector3(0, 0.025, -0.55), Vector3(0.075, 0.075, barrel_length), Color("2b3038"))
		_add_weapon_box(Vector3(0, -0.2, -0.08), Vector3(0.13, 0.36, 0.17), Color("20262d"), Vector3(-12, 0, 0))
		_add_weapon_box(Vector3(0, -0.13, 0.24), mag_size, Color("313a45"), Vector3(10, 0, 0))
		_add_weapon_box(Vector3(0, 0.13, -0.18), Vector3(0.08, 0.08, 0.22), Color("151a20"))
		_create_muzzle(Vector3(0, 0.025, -0.77 - max(0.0, body_length - 0.62) * 0.6))

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

func _add_weapon_cylinder(pos, radius, height, color, rotation_deg = Vector3.ZERO):
	var mesh_instance = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.rotation_degrees = rotation_deg
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.48
	mat.roughness = 0.26
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
	var stats = current_stats()
	var target_fov = float(stats.get("aim_fov", 60.0)) if aiming else 82.0
	camera.fov = lerp(camera.fov, target_fov, min(1.0, delta * 11.0))
	recoil = move_toward(recoil, 0.0, delta * float(stats.get("recoil_recovery", 5.2)))
	if reload_animation_time > 0.0:
		reload_animation_time = max(0.0, reload_animation_time - delta)
	if is_instance_valid(weapon_root):
		var move_amount = Vector2(velocity.x, velocity.z).length() / speed if alive else 0.0
		var sway_x = sin(bob_time * 0.5) * 0.012 * move_amount
		var sway_y = abs(cos(bob_time)) * 0.012 * move_amount
		var base_position = Vector3(0.03, -0.2, -0.53) if aiming else Vector3(0.34, -0.31, -0.58)
		var target_position = base_position + Vector3(sway_x, -sway_y - recoil * 0.055, recoil * 0.09)
		var target_rotation = Vector3(-2.0, 0.0, 0.0)
		if reload_animation_time > 0.0 and reload_animation_duration > 0.0:
			var progress = 1.0 - reload_animation_time / reload_animation_duration
			var arc = sin(progress * PI)
			target_position += Vector3(0.2 * arc, -0.36 * arc, 0.08 * arc)
			target_rotation = Vector3(-18.0 * arc, 0.0, 32.0 * arc)
		weapon_root.position = weapon_root.position.lerp(target_position, min(1.0, delta * 18.0))
		weapon_root.rotation_degrees = weapon_root.rotation_degrees.lerp(target_rotation, min(1.0, delta * 16.0))
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
	max_health = float(SaveData.player_max_health())
	health = max_health
	set_armor_capacity(SaveData.armor_capacity())
	headshot_damage_multiplier = 0.5 if SaveData.helmet_owned else 1.0
	medkits_used_life = 0
	grenades_used_life = 0
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
		return "%s • %d шагов" % [stats.get("name", "Оружие"), int(stats.range)]
	return "%s • ур.%d • мощь %d" % [stats.get("name", "Оружие"), int(stats.level), int(stats.power)]
