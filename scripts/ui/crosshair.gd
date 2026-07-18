extends Control
class_name BoomCrosshair

var hud

func _draw():
	var color = Color("ef476f") if hud and hud.crosshair_enemy else Color.WHITE
	draw_line(Vector2(25, 7), Vector2(25, 18), color, 3)
	draw_line(Vector2(25, 32), Vector2(25, 43), color, 3)
	draw_line(Vector2(7, 25), Vector2(18, 25), color, 3)
	draw_line(Vector2(32, 25), Vector2(43, 25), color, 3)
	draw_circle(Vector2(25, 25), 2.5, color)
