extends Control
class_name BoomCrosshair

var hud

func _draw():
	var enemy = hud and hud.crosshair_enemy
	var color = Color("ef476f") if enemy else Color.WHITE
	var kick = hud.crosshair_kick if hud else 0.0
	var gap = 7.0 + kick * 11.0
	var arm = 10.0
	var c = size * 0.5
	draw_line(c + Vector2(0, -gap - arm), c + Vector2(0, -gap), color, 3.0)
	draw_line(c + Vector2(0, gap), c + Vector2(0, gap + arm), color, 3.0)
	draw_line(c + Vector2(-gap - arm, 0), c + Vector2(-gap, 0), color, 3.0)
	draw_line(c + Vector2(gap, 0), c + Vector2(gap + arm, 0), color, 3.0)
	draw_circle(c, 2.2, color)
	if hud and hud.shot_flash_time > 0.0:
		draw_circle(c, 4.3, Color("ffca3a"), false, 2.0)
	if hud and hud.hit_marker_time > 0.0:
		var hit_color = Color("ffca3a")
		draw_line(c + Vector2(-13, -13), c + Vector2(-5, -5), hit_color, 4.0)
		draw_line(c + Vector2(13, -13), c + Vector2(5, -5), hit_color, 4.0)
		draw_line(c + Vector2(-13, 13), c + Vector2(-5, 5), hit_color, 4.0)
		draw_line(c + Vector2(13, 13), c + Vector2(5, 5), hit_color, 4.0)
