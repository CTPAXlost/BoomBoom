extends Control
class_name BoomLookPad

signal looked(value)

var finger = -1
var blocked_controls = []
var left_boundary_ratio = 0.31

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func set_blocked_controls(controls):
	blocked_controls = controls

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger == -1 and _can_start(event.position):
				finger = event.index
		elif event.index == finger:
			finger = -1
	elif event is InputEventScreenDrag and event.index == finger:
		var viewport_size = get_viewport().get_visible_rect().size
		var scale_factor = 1280.0 / max(viewport_size.x, 1.0)
		looked.emit(event.relative * scale_factor)

func _can_start(screen_position):
	var viewport_size = get_viewport().get_visible_rect().size
	if screen_position.x < viewport_size.x * left_boundary_ratio:
		return false
	for control in blocked_controls:
		if is_instance_valid(control) and control.visible and control.get_global_rect().has_point(screen_position):
			return false
	return true

func cancel_touch():
	finger = -1
