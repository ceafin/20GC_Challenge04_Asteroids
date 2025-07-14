extends Node2D
class_name Starfield

signal level_finished

func _on_entity_requested_wrap( entity: Node2D ) -> void:
	var screen_size : Vector2 = get_viewport().get_visible_rect().size
	entity.position = Vector2(
		wrapf( entity.position.x, 0.0, screen_size.x ),
		wrapf( entity.position.y, 0.0, screen_size.y )
	)
	

func register_wrappable( entity: Node2D ) -> void:
	entity.requested_wrap.connect( Callable( self, "_on_entity_requested_wrap" ) )
