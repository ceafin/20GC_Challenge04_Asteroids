extends StaticBody2D
class_name Asteroid


var speed : float = 10.0
var velocity : Vector2 = Vector2.ZERO

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal requested_wrap


func _ready() -> void:
	velocity = Vector2( randf_range(-1.0,1.0), randf_range(-1.0,1.0) ).normalized() * speed
	

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Asteroid said, \"Warp Please!\"")
	requested_wrap.emit( self )
