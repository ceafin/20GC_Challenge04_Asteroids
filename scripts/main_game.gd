extends Node
class_name MainGame

const BIG_ASTEROID : Array[PackedScene] = [
	preload("res://scenes/asteroid_big_a.tscn"),
	preload("res://scenes/asteroid_big_b.tscn"),
	preload("res://scenes/asteroid_big_c.tscn"),
	preload("res://scenes/asteroid_big_d.tscn")
]
const SPACESHIP : PackedScene = preload("res://scenes/spaceship.tscn")
const BULLET : PackedScene = preload("res://scenes/bullet.tscn")

var starfield : Starfield
var current_level : int = 1
var current_lives : int = 3
var spaceship : Spaceship

func _ready() -> void:
	starfield = find_child("Starfield")
	starfield.level_finished.connect( Callable( self, "_start_new_level" ) )
	
	_start_new_level()

func _start_new_level() -> void:
	await get_tree().create_timer(2.0).timeout
	_spawn_asteroids( current_level + 6 )
	await get_tree().create_timer(2.0).timeout
	_spawn_spaceship()

func _spawn_asteroids( count: int ) -> void:
	var new_asteroid : Asteroid
	for i: int in count:
		new_asteroid = BIG_ASTEROID[ randi_range( 0, 3 ) ].instantiate()
		new_asteroid.owner = starfield
		new_asteroid.add_to_group("Asteroids")
		starfield.add_child(new_asteroid)
		starfield.register_wrappable(new_asteroid)
		new_asteroid.position = Vector2(
			randf_range(0, get_viewport().get_visible_rect().size.x),
			randf_range(0, get_viewport().get_visible_rect().size.y)
		)

func _spawn_spaceship( tries : int = 5 ) -> void:
		
	# Conjure up a new spaceship
	var new_spaceship : Spaceship = SPACESHIP.instantiate()
	spaceship = new_spaceship
	new_spaceship.owner = starfield
	new_spaceship.add_to_group("Spaceship")
	
	# Set new ship shapes and state
	var space_state : PhysicsDirectSpaceState2D = get_viewport().get_world_2d().direct_space_state
	var shape : Shape2D = spaceship.get_node("TeleportProbe/TeleportCollisionShape2D").shape.duplicate(true)
	
	# Position and Safety
	var spawn_position : Vector2
	var found_safe : bool = false
	
	# Try center spawn first
	if tries > 0:
		spawn_position = get_viewport().get_visible_rect().size / 2
		var params : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D(0, spawn_position)
		params.exclude = []
		params.collision_mask = 1 << 1  # Asteroids on layer 2
		
		var result : Array[Dictionary] = space_state.intersect_shape(params, 1)

		if result.is_empty():
			found_safe = true
		else:
			print("Center spawn blocked! Tries left: ", tries)
			await get_tree().create_timer(0.3).timeout
			_spawn_spaceship( tries - 1 )
			return
	else:
		# Fallback to teleport-style random spawn
		print("⚠️ Falling back to random spawn after center retry fail!")
		var max_attempts : int = 10
		while max_attempts > 0 and not found_safe:
			spawn_position = Vector2(
				randf_range(0, get_viewport().get_visible_rect().size.x),
				randf_range(0, get_viewport().get_visible_rect().size.y)
			)

			var params : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
			params.shape = shape
			params.transform = Transform2D(0, spawn_position)
			params.exclude = []
			params.collision_mask = 1 << 1
			
			var result : Array[Dictionary] = space_state.intersect_shape(params, 1)

			if result.is_empty():
				found_safe = true
			else:
				max_attempts -= 1

		if not found_safe:
			print("❌ Could not find a safe spawn location!")
			return 
	
	# Okay, all clear to spawn
	starfield.add_child(new_spaceship)
	starfield.register_wrappable(new_spaceship)
	
	# Hook it up
	new_spaceship.fired_bullet.connect( Callable( self, "_on_spaceship_fired" ) )
	new_spaceship.spaceship_died.connect( Callable( self, "_on_spaceship_died" ) )
	
	# Place in location
	new_spaceship.position = spawn_position
	
func _spawn_new_bullet() -> void:
	var new_bullet : Bullet
	new_bullet = BULLET.instantiate()
	new_bullet.owner = starfield
	new_bullet.add_to_group("Bullets")
	starfield.add_child(new_bullet)
	starfield.register_wrappable(new_bullet)
	new_bullet.position = spaceship.position
	new_bullet.rotation = spaceship.rotation
	new_bullet.velocity = Vector2.RIGHT.rotated(spaceship.rotation)

func _on_spaceship_fired() -> void:
	_spawn_new_bullet()
	

func _on_spaceship_died() -> void:
	current_lives -= 1
	
	if current_lives >= 0:
		await get_tree().create_timer(2.0).timeout
		_spawn_spaceship()
		print( "Lives left: " + str( current_lives ) )
	else:
		game_over()
	

func game_over() -> void:
	get_tree().quit()
