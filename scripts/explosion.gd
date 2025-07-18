extends AnimatedSprite2D
class_name Explosion



func _ready() -> void:
	pass #play sound

func _on_animation_finished() -> void:
	if is_inside_tree():
		queue_free()
