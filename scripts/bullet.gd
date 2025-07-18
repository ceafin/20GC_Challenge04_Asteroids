extends Area2D
class_name Bullet

var speed : float = 200.0
var velocity : Vector2 = Vector2.RIGHT

signal requested_wrap

func _physics_process( delta: float ) -> void:
	position += velocity * speed * delta


func _on_bullet_life_timer_timeout() -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Bullet said, \"Warp Please!\"")
	requested_wrap.emit( self )


func _on_body_entered(body: Node2D) -> void:
	print( "Bullet hit a: " + str( body ) )
	if body is Asteroid:
		print( "Bullet blows it up!" )
		body.explode()
		if is_inside_tree():
			queue_free()
