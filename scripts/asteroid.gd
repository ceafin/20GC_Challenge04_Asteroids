extends StaticBody2D
class_name Asteroid

const EXPLOSION : PackedScene = preload("res://scenes/explosion.tscn")

var size : int = 2
var speed : float = 2.0
var velocity : Vector2 = Vector2.ZERO

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal requested_wrap
signal destroyed( size: int, global_position: Vector2 )


func _ready() -> void:
	velocity = Vector2( randf_range(-1.0,1.0), randf_range(-1.0,1.0) ).normalized() * speed
	

func _physics_process(delta: float) -> void:
	position += velocity * delta * speed

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	requested_wrap.emit( self )

func explode() -> void:
	var boom : Explosion = EXPLOSION.instantiate()
	boom.position = position
	boom.z_index = 100
	get_parent().add_child( boom )
	destroyed.emit( size, global_position )
	await get_tree().process_frame
	if is_inside_tree():
		queue_free()
