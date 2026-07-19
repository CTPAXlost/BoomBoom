extends Control
class_name BoomScopeOverlay

var active = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

func set_active(value):
	active = bool(value)
	visible = active
	queue_redraw()

func _draw():
	if not active:
		return
	var center = size * 0.5
	var radius = min(size.x, size.y) * 0.37
	var outer_radius = max(size.x, size.y) * 1.35
	var shade = Color(0.0, 0.0, 0.0, 0.94)
	var segments = 72
	for i in range(segments):
		var a0 = TAU * float(i) / float(segments)
		var a1 = TAU * float(i + 1) / float(segments)
		var p0 = center + Vector2(cos(a0), sin(a0)) * radius
		var p1 = center + Vector2(cos(a1), sin(a1)) * radius
		var q1 = center + Vector2(cos(a1), sin(a1)) * outer_radius
		var q0 = center + Vector2(cos(a0), sin(a0)) * outer_radius
		draw_polygon(PackedVector2Array([p0, p1, q1, q0]), PackedColorArray([shade]))
	draw_circle(center, radius, Color(0.1, 0.13, 0.15, 1.0), false, 7.0)
	draw_circle(center, radius - 5.0, Color(0.75, 0.82, 0.86, 0.7), false, 2.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), Color(0.93, 0.96, 0.98, 0.8), 1.6)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), Color(0.93, 0.96, 0.98, 0.8), 1.6)
	for offset in [40.0, 80.0, 120.0]:
		draw_line(center + Vector2(-8.0, offset), center + Vector2(8.0, offset), Color(0.93, 0.96, 0.98, 0.75), 2.0)
		draw_line(center + Vector2(-8.0, -offset), center + Vector2(8.0, -offset), Color(0.93, 0.96, 0.98, 0.75), 2.0)
	draw_circle(center, 3.0, Color("ef476f"))
