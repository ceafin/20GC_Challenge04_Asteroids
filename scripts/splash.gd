extends Node2D

func _process(delta: float) -> void:
	var input : bool = Input.is_action_just_pressed("ui_accept")
	
	if input:
		get_tree().change_scene_to_file( "res://scenes/main_game.tscn" )
