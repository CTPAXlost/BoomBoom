extends Control
class_name VirtualJoystick

signal vector_changed(value)

var finger = -1
var center = Vector2(145, 155)
var knob = center
var radius = 82.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			_update(event.position)
		elif not event.pressed and event.index == finger:
			_release()
	elif event is InputEventScreenDrag and event.index == finger:
		_update(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			finger = -2
			_update(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and finger == -2:
		_update(event.position)

func _release():
	finger = -1
	knob = center
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()

func _update(pos):
	var delta = pos - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	knob = center + delta
	vector_changed.emit(Vector2(delta.x / radius, -delta.y / radius))
	queue_redraw()

func _draw():
	draw_circle(center, 100, Color(0.04, 0.1, 0.16, 0.58))
	draw_arc(center, 100, 0, TAU, 64, Color("23e6ff"), 4)
	draw_circle(knob, 45, Color(0.14, 0.9, 1.0, 0.62))
