extends AnimatedSprite2D
class_name SpawnWobba


func _on_animation_finished() -> void:
	if self.is_inside_tree():
		await get_tree().process_frame
		self.queue_free()
