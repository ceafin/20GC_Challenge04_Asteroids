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
	_spawn_spaceship()
	await get_tree().create_timer(2.0).timeout
	_spawn_asteroids( current_level + 2 )

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

func _spawn_spaceship() -> void:
	var new_spaceship : Spaceship = SPACESHIP.instantiate()
	
	spaceship = new_spaceship
	
	new_spaceship.owner = starfield
	new_spaceship.add_to_group("Spaceship")
	
	starfield.add_child(new_spaceship)
	starfield.register_wrappable(new_spaceship)
	
	new_spaceship.fired_bullet.connect( Callable( self, "_on_spaceship_fired" ) )
	new_spaceship.spaceship_died.connect( Callable( self, "_on_spaceship_died" ) )
	
	new_spaceship.position = Vector2(
		roundf( get_viewport().get_visible_rect().size.x / 2 ),
		roundf( get_viewport().get_visible_rect().size.y / 2 )
		)
	
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
		_spawn_spaceship()
		print( "Lives left: " + str( current_lives ) )
	else:
		game_over()
	

func game_over() -> void:
	get_tree().quit()
