extends Control

class_name Reticle

var rotation_speed : float = 2.0

func _physics_process(delta: float) -> void:
	$TextureRect.rotation += rotation_speed * delta

func adjust_reticle(r_pos: Vector2, percent: float):
	var r_scale : float = 4.0 - percent * 4.0
	r_scale = clampf(r_scale, 2.0, 4.0)
	$TextureRect.scale = Vector2(r_scale, r_scale)
	$TextureRect.position = r_pos - ($TextureRect.size / 2.0 * $TextureRect.scale / 2.0)
