extends Control
class_name LookPad

signal looked(value)

var finger = -1
var last_pos = Vector2.ZERO

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			last_pos = event.position
		elif not event.pressed and event.index == finger:
			finger = -1
	elif event is InputEventScreenDrag and event.index == finger:
		looked.emit(event.position - last_pos)
		last_pos = event.position
