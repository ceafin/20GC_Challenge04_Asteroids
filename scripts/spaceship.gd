extends CharacterBody2D
class_name Spaceship

const SPAWN_WOBBA : PackedScene = preload("res://scenes/spawn_wobba.tscn")

@export var rotation_speed : float = 5.0 # in radians
@export var acceleration : float = 500.0
@export var max_speed : float = 100.0

var is_dead: bool = false

@onready var ship_collision_shape_2d: CollisionShape2D = $ShipCollisionShape2D
@onready var teleport_collision_shape_2d: CollisionShape2D = $TeleportProbe/TeleportCollisionShape2D
@onready var teleport_timer: Timer = $TeleportTimer

signal requested_wrap
signal fired_bullet
signal spaceship_died

func _ready() -> void:
	velocity = Vector2.ZERO
	

func _physics_process( delta: float ) -> void:
	
	var teleport : bool = Input.is_action_just_pressed( "teleport" )
	if teleport:
		_teleport()
	
	var shoot : bool = Input.is_action_just_pressed( "shoot" )
	if shoot:
		fired_bullet.emit()
	
	var direction : float = Input.get_axis("turn_left", "turn_right")
	if direction != 0:
		rotation += direction * rotation_speed * delta
	
	var thrust : float = Input.get_axis("backwards", "forward")
	if thrust != 0:
		var forward : Vector2 = Vector2.RIGHT.rotated(rotation)
		velocity += forward * acceleration * thrust * delta
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
	
	move_and_slide()
	
	for i : int in get_slide_collision_count():
		if is_dead:
			break
		
		var collision : KinematicCollision2D = get_slide_collision( i )
		if collision.get_collider().is_in_group( "Asteroids" ):
			is_dead = true
			ship_collision_shape_2d.disabled = true
			set_physics_process( false )
			print( "💥!" )
			spaceship_died.emit()
			queue_free()
	


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Spaceship said, \"Warp Please!\"")
	requested_wrap.emit( self )


func _on_teleport_timer_timeout() -> void:
	var space_state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape : Shape2D = teleport_collision_shape_2d.shape.duplicate( true )
	
	var tries : int = 10
	var found_safe : bool = false
	var new_position : Vector2
	
	while tries > 0 and not found_safe:
		new_position = Vector2(
			randf_range(0, get_viewport().get_visible_rect().size.x),
			randf_range(0, get_viewport().get_visible_rect().size.y)
		)
	
		# var result : Array[Dictionary] = space_state.intersect_shape( PhysicsShapeQueryParameters2D.new(), 1 )
		var params : PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		params.shape = shape
		params.transform = Transform2D( 0, new_position )
		params.exclude = [ self ]
		#params.collision_mask = collision_layer
		params.collision_mask = 1 << 1 # Asteroids on "2"

		var collisions : Array[Dictionary] = space_state.intersect_shape( params, 1 )
				
		if collisions.size() > 0:
			print( "Teleport position blocked! Trying another..." )
			
		if collisions.size() == 0:
			found_safe = true
		
		tries -= 1

	if found_safe:
		position = new_position
		spawn_a_wobba()
		visible = true
		ship_collision_shape_2d.disabled = false
		set_physics_process( true )
	else:
		print("No safe place to teleport!")
	
func _teleport() -> void:
	visible = false
	velocity = Vector2.ZERO
	set_physics_process( false )
	ship_collision_shape_2d.disabled = true
	teleport_timer.start()
	
func spawn_a_wobba() -> void:
	var new_wobba : SpawnWobba = SPAWN_WOBBA.instantiate()
	self.get_parent().add_child( new_wobba )
	new_wobba.position = self.position
