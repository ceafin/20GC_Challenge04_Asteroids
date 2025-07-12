extends CharacterBody2D
class_name Asteroid

var speed : float = 10.0

func _ready() -> void:
	velocity = Vector2( randf_range(-1.0,1.0), randf_range(-1.0,1.0) ).normalized() * speed
	
func _physics_process( delta: float ) -> void:
	move_and_slide()
