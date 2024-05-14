extends CharacterBody2D

const FOOTPRINT = preload("res://footprint.tscn")

const ACCEL := 100.0
const MAX_SPEED := 80.0

# Spots to drop footprints at
# Can't use left/right foot as its not obvious from animations
@onready var east_side: Marker2D = $EastSide
@onready var west_side: Marker2D = $WestSide

@onready var animation_tree: AnimationTree = $AnimationTree

var speed := 0.0

var last_active_direction := Vector2.DOWN
@export var idling := false
@export var exhausted := false

func _physics_process(delta: float) -> void:

	var speed := minf(speed + ACCEL * ACCEL * delta, MAX_SPEED)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		idling = false
		last_active_direction = direction
		velocity = direction.normalized() * speed
	else:
		idling = true
		velocity = Vector2.ZERO
		speed = maxf(0.0, speed - ACCEL * delta)
		
	
	animation_tree["parameters/Movement/blend_position"] = direction
	animation_tree["parameters/Idle/Exhausted/blend_position"] = last_active_direction
	animation_tree["parameters/Idle/Idle/blend_position"] = last_active_direction
		
		
		

	move_and_slide()


func _anim_place_footprint(spawn_west: bool):
	if spawn_west:
		var footprint = FOOTPRINT.instantiate()
		footprint.global_position = west_side.global_position
		get_parent().add_child(footprint)
	else:
		var footprint = FOOTPRINT.instantiate()
		footprint.global_position = east_side.global_position
		get_parent().add_child(footprint)
