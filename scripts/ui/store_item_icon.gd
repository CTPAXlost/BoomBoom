extends Control
class_name BoomStoreItemIcon

var item_id = "rifle"
var accent = Color("23e6ff")

func configure(p_item_id, p_accent = Color("23e6ff")):
	item_id = str(p_item_id)
	accent = p_accent
	queue_redraw()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(118, 76)
	queue_redraw()

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.025, 0.075, 0.12, 0.92), true)
	draw_rect(rect.grow(-2.0), Color(accent, 0.7), false, 2.0)
	match item_id:
		"medkit":
			_draw_medkit()
		"grenade":
			_draw_grenade()
		"flash":
			_draw_flash_grenade()
		"repair":
			_draw_repair_kit()
		"armor":
			_draw_armor()
		"helmet":
			_draw_helmet()
		_:
			_draw_weapon()

func _draw_weapon():
	var y = size.y * 0.5
	var body_start = Vector2(size.x * 0.17, y - 10.0)
	var body_size = Vector2(size.x * 0.49, 20.0)
	var barrel_length = 25.0
	var magazine_size = Vector2(13.0, 23.0)
	if item_id == "shotgun":
		body_size = Vector2(size.x * 0.54, 18.0)
		barrel_length = 31.0
	elif item_id == "machinegun":
		body_size = Vector2(size.x * 0.5, 24.0)
		magazine_size = Vector2(23.0, 27.0)
	elif item_id == "sniper":
		body_size = Vector2(size.x * 0.56, 15.0)
		barrel_length = 36.0
	elif item_id == "rifle_vortex":
		body_size = Vector2(size.x * 0.51, 18.0)
		barrel_length = 29.0
	elif item_id == "rifle_bastion":
		body_size = Vector2(size.x * 0.53, 23.0)
		barrel_length = 27.0
	elif item_id == "rifle_phoenix":
		body_size = Vector2(size.x * 0.56, 17.0)
		barrel_length = 32.0

	draw_rect(Rect2(body_start, body_size), accent, true)
	draw_rect(Rect2(Vector2(body_start.x + body_size.x, y - 4.0), Vector2(barrel_length, 8.0)), Color("d9e3ec"), true)
	draw_rect(Rect2(Vector2(body_start.x - 15.0, y - 7.0), Vector2(18.0, 14.0)), Color("5e6b76"), true)
	draw_polygon(
		PackedVector2Array([
			Vector2(body_start.x + 17.0, y + 9.0),
			Vector2(body_start.x + 31.0, y + 9.0),
			Vector2(body_start.x + 34.0, y + 27.0),
			Vector2(body_start.x + 19.0, y + 27.0)
		]),
		PackedColorArray([Color("27323b")])
	)
	draw_rect(Rect2(Vector2(body_start.x + body_size.x * 0.55, y + 7.0), magazine_size), Color("303944"), true)
	if item_id == "machinegun":
		draw_circle(Vector2(body_start.x + body_size.x * 0.56, y + 21.0), 13.0, Color("3b4651"))
	if item_id == "sniper":
		draw_rect(Rect2(Vector2(body_start.x + body_size.x * 0.28, y - 22.0), Vector2(34.0, 8.0)), Color("111820"), true)
		draw_circle(Vector2(body_start.x + body_size.x * 0.28, y - 18.0), 6.0, Color("8cff98"), false, 2.0)
	if item_id == "shotgun":
		draw_rect(Rect2(Vector2(body_start.x + body_size.x * 0.68, y + 6.0), Vector2(22.0, 8.0)), Color("80522f"), true)

func _draw_medkit():
	var r = Rect2(Vector2(size.x * 0.23, size.y * 0.18), Vector2(size.x * 0.54, size.y * 0.64))
	draw_rect(r, Color("d93b4b"), true)
	draw_rect(r, Color("ff8190"), false, 3.0)
	draw_rect(Rect2(Vector2(size.x * 0.43, size.y * 0.27), Vector2(size.x * 0.14, size.y * 0.46)), Color.WHITE, true)
	draw_rect(Rect2(Vector2(size.x * 0.32, size.y * 0.42), Vector2(size.x * 0.36, size.y * 0.16)), Color.WHITE, true)
	draw_rect(Rect2(Vector2(size.x * 0.41, size.y * 0.09), Vector2(size.x * 0.18, size.y * 0.11)), Color("7e2630"), true)

func _draw_grenade():
	var c = Vector2(size.x * 0.5, size.y * 0.54)
	draw_circle(c, size.y * 0.27, Color("4f6a49"))
	draw_circle(c, size.y * 0.27, Color("a8c59f"), false, 3.0)
	draw_rect(Rect2(Vector2(c.x - 9.0, c.y - 31.0), Vector2(18.0, 13.0)), Color("2f3f30"), true)
	draw_arc(Vector2(c.x + 8.0, c.y - 28.0), 12.0, -1.4, 1.4, 20, Color("d8e6f0"), 3.0)
	draw_line(Vector2(c.x - 14.0, c.y - 7.0), Vector2(c.x + 14.0, c.y + 10.0), Color(1, 1, 1, 0.16), 3.0)

func _draw_armor():
	var c = Vector2(size.x * 0.5, size.y * 0.48)
	var shield = PackedVector2Array([
		Vector2(c.x, c.y - 27.0),
		Vector2(c.x + 29.0, c.y - 14.0),
		Vector2(c.x + 22.0, c.y + 20.0),
		Vector2(c.x, c.y + 34.0),
		Vector2(c.x - 22.0, c.y + 20.0),
		Vector2(c.x - 29.0, c.y - 14.0)
	])
	draw_polygon(shield, PackedColorArray([Color("287f9f")]))
	draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[5], shield[0]]), Color("77d8ff"), 4.0)
	draw_line(Vector2(c.x, c.y - 17.0), Vector2(c.x, c.y + 21.0), Color(1, 1, 1, 0.55), 4.0)

func _draw_helmet():
	var c = Vector2(size.x * 0.5, size.y * 0.54)
	draw_arc(c, 29.0, PI, TAU, 42, Color("a8b4be"), 16.0)
	draw_rect(Rect2(Vector2(c.x - 36.0, c.y - 4.0), Vector2(72.0, 13.0)), Color("3c4a54"), true)
	draw_rect(Rect2(Vector2(c.x + 17.0, c.y + 4.0), Vector2(12.0, 20.0)), Color("2c353d"), true)
	draw_line(Vector2(c.x - 12.0, c.y + 8.0), Vector2(c.x + 9.0, c.y + 21.0), Color("d8e6f0"), 3.0)

func _draw_flash_grenade():
	var c = Vector2(size.x * 0.5, size.y * 0.54)
	draw_circle(c, size.y * 0.25, Color("dce8ef"))
	draw_circle(c, size.y * 0.25, Color("ffffff"), false, 3.0)
	draw_rect(Rect2(Vector2(c.x - 8.0, c.y - 30.0), Vector2(16.0, 12.0)), Color("687785"), true)
	for angle in range(0, 360, 45):
		var direction = Vector2.from_angle(deg_to_rad(float(angle)))
		draw_line(c + direction * 22.0, c + direction * 34.0, Color("ffef88"), 3.0)
	draw_circle(c, 7.0, Color("ffef88"))

func _draw_repair_kit():
	var r = Rect2(Vector2(size.x * 0.22, size.y * 0.22), Vector2(size.x * 0.56, size.y * 0.58))
	draw_rect(r, Color("287f9f"), true)
	draw_rect(r, Color("77d8ff"), false, 3.0)
	draw_rect(Rect2(Vector2(size.x * 0.39, size.y * 0.12), Vector2(size.x * 0.22, size.y * 0.13)), Color("23445d"), true)
	var c = Vector2(size.x * 0.5, size.y * 0.52)
	draw_circle(c, 13.0, Color("d8e6f0"), false, 5.0)
	draw_line(c + Vector2(-18, 18), c + Vector2(18, -18), Color("d8e6f0"), 5.0)
	draw_circle(c + Vector2(14, -14), 5.0, Color("ffca3a"))
