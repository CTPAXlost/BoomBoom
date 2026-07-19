extends Control
class_name BoomTouchJoystick

signal vector_changed(value)

var finger = -1
var mouse_active = false
var center = Vector2.ZERO
var knob = Vector2.ZERO
var radius = 88.0
var deadzone = 0.12
var active = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_resolve_idle_center()
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_RESIZED and not active:
		_resolve_idle_center()

func _resolve_idle_center():
	center = Vector2(min(size.x * 0.38, 155.0), size.y - min(size.y * 0.38, 145.0))
	knob = center
	radius = clamp(min(size.x, size.y) * 0.27, 70.0, 96.0)
	queue_redraw()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			active = true
			center = _clamp_center(event.position)
			knob = center
			_update(event.position)
			accept_event()
		elif not event.pressed and event.index == finger:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		_update(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_active = true
			active = true
			center = _clamp_center(event.position)
			knob = center
			_update(event.position)
		else:
			mouse_active = false
			_release()
		accept_event()
	elif event is InputEventMouseMotion and mouse_active:
		_update(event.position)
		accept_event()

func _clamp_center(pos):
	var margin = radius + 12.0
	return Vector2(
		clamp(pos.x, margin, max(margin, size.x - margin)),
		clamp(pos.y, margin, max(margin, size.y - margin))
	)

func _release():
	finger = -1
	mouse_active = false
	active = false
	vector_changed.emit(Vector2.ZERO)
	_resolve_idle_center()

func _update(pos):
	var delta = pos - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	knob = center + delta
	var value = delta / radius
	var length = value.length()
	if length <= deadzone:
		value = Vector2.ZERO
	else:
		var strength = inverse_lerp(deadzone, 1.0, min(length, 1.0))
		value = value.normalized() * strength
	vector_changed.emit(value)
	queue_redraw()

func force_release():
	_release()

func _draw():
	var alpha = 0.68 if active else 0.42
	draw_circle(center, radius + 19.0, Color(0.025, 0.075, 0.12, alpha))
	draw_arc(center, radius + 19.0, 0.0, TAU, 64, Color(0.14, 0.9, 1.0, alpha), 4.0)
	draw_circle(center, radius * deadzone, Color(0.14, 0.9, 1.0, 0.14))
	draw_circle(knob, radius * 0.48, Color(0.14, 0.9, 1.0, 0.72 if active else 0.48))
