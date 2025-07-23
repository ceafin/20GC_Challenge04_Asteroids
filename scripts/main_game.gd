extends Node
class_name MainGame

enum Size {
	LIL, MED, BIG
}

const BIG_ASTEROID : Array[PackedScene] = [
	preload("res://scenes/asteroid_big_a.tscn"),
	preload("res://scenes/asteroid_big_b.tscn"),
	preload("res://scenes/asteroid_big_c.tscn"),
	preload("res://scenes/asteroid_big_d.tscn")
]

const MED_ASTEROID : Array[PackedScene] = [
	preload("res://scenes/asteroid_med_a.tscn"),
	preload("res://scenes/asteroid_med_b.tscn"),
	preload("res://scenes/asteroid_med_c.tscn"),
	preload("res://scenes/asteroid_med_d.tscn")
]

const LIL_ASTEROID : Array[PackedScene] = [
	preload("res://scenes/asteroid_lil_a.tscn"),
	preload("res://scenes/asteroid_lil_b.tscn"),
	preload("res://scenes/asteroid_lil_c.tscn"),
	preload("res://scenes/asteroid_lil_d.tscn")
]
const SPACESHIP : PackedScene = preload("res://scenes/spaceship.tscn")
const BULLET : PackedScene = preload("res://scenes/bullet.tscn")
const SPAWN_WOBBA : PackedScene = preload("res://scenes/spawn_wobba.tscn")

var starfield : Starfield
var spaceship : Spaceship
var current_level : int = 1

var current_lives : int = 3:
	set( value ):
		_current_lives = value
		ui.update_lives( value )
	get:
		return _current_lives
var _current_lives: int = 3

var player_score: int = 0:
	set( value ):
		_player_score = value
		ui.update_score( value )
	get:
		return _player_score
var _player_score: int = 0  # internal backing variable


@onready var ui: GameUI = $GameOverlay/UI

func _ready() -> void:
	starfield = find_child("Starfield")
	starfield.level_finished.connect( Callable( self, "_start_new_level" ) )
	current_lives = 3
	_start_new_level()

func _start_new_level() -> void:
	await get_tree().create_timer(2.0).timeout
	_spawn_asteroids( current_level + 1 )
	await get_tree().create_timer(2.0).timeout
	_spawn_spaceship()

func _spawn_asteroids( count: int ) -> void:
	ui.display_message( "Asteroids Inbound!", 1.5 )
	await get_tree().create_timer(2.0).timeout
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
		new_asteroid.destroyed.connect( Callable( self, "_on_asteroid_destroyed" ) )

func _spawn_smaller_asteroids( size: Size, asteroid_pool: Array[PackedScene], position: Vector2 ) -> void:
	var smaller_asteroid : Asteroid
	var count : int = 2 if size == 2 else 3
	for i: int in count:
		smaller_asteroid = asteroid_pool[ randi_range( 0, 3 ) ].instantiate()
		smaller_asteroid.owner = starfield
		smaller_asteroid.add_to_group( "Asteroids" )
		starfield.add_child( smaller_asteroid )
		starfield.register_wrappable( smaller_asteroid )
		smaller_asteroid.size = size - 1
		smaller_asteroid.speed = 3 if size == 2 else 6
		smaller_asteroid.position = position #+ Vector2( randf_range( -10, 10 ), randf_range( -10, 10 ) )
		smaller_asteroid.destroyed.connect( Callable( self, "_on_asteroid_destroyed" ) )


func _spawn_spaceship( tries : int = 5 ) -> void:
	ui.display_message( "Warping In; Good Luck!", 1.5 )
	await get_tree().create_timer(2.0).timeout
	
	# Conjure up a new spaceship
	var new_spaceship : Spaceship = SPACESHIP.instantiate()
	var spawn_wobba : SpawnWobba = SPAWN_WOBBA.instantiate()
	
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
			ui.display_message( "Warp Destination Block! Trying again...", 2.0 )
			await get_tree().create_timer(4.0).timeout
			_spawn_spaceship( tries - 1 )
			return
	else:
		# Fallback to teleport-style random spawn
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
			print("No safe spawn location!")
			return 
	
	# Okay, all clear to spawn
	starfield.add_child(new_spaceship)
	starfield.register_wrappable(new_spaceship)
	starfield.add_child(spawn_wobba)
	
	# Hook it up
	new_spaceship.fired_bullet.connect( Callable( self, "_on_spaceship_fired" ) )
	new_spaceship.spaceship_died.connect( Callable( self, "_on_spaceship_died" ) )
	
	# Place in location
	new_spaceship.position = spawn_position
	spawn_wobba.position = spawn_position
	
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
	

func _on_asteroid_destroyed( size: Size, position: Vector2 ) -> void:
	
	match size:
		Size.BIG:
			player_score += 100
			_spawn_smaller_asteroids( size, MED_ASTEROID, position )
		Size.MED:
			player_score += 200
			_spawn_smaller_asteroids( size, LIL_ASTEROID, position )
		Size.LIL:
			player_score += 400
	
	check_for_new_wave()
	

func check_for_new_wave() -> void:
	await get_tree().process_frame
	var asteroid_count : int = get_tree().get_nodes_in_group( "Asteroids" ).size()
	if asteroid_count <= 1:
		current_level += 1
		spaceship.leave_level()
		ui.display_message( "Wave Cleared!", 1.0 )
		await get_tree().create_timer(2.0).timeout
		_start_new_level()

func game_over() -> void:
	ui.display_message( "Game Over!", 4.0 )
	await get_tree().create_timer(8.0).timeout
	get_tree().quit()
