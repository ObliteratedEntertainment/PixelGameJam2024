extends CharacterBody2D

const FOOTPRINT = preload("res://footprint.tscn")

const ACCEL := 100.0
const MAX_SPEED := 80.0

@onready var zone_detector: Area2D = $ZoneDetector
@onready var shade_detector: Area2D = $ShadeDetector
@onready var power_up_detector: Area2D = $PowerUpDetector


# Spots to drop footprints at
# Can't use left/right foot as its not obvious from animations
@onready var east_side: Marker2D = $EastSide
@onready var west_side: Marker2D = $WestSide

@onready var animation_tree: AnimationTree = $AnimationTree

var speed := 0.0

var last_active_direction := Vector2.DOWN
@export var idling := false
@export var exhausted := false
@export var dead := false

# Water system
var current_water := 100.0
var unused_flasks := 0
var total_flasks := 0
var in_oasis := 0
var in_shade := 0 # Needs to be a counter because there may be overlaps

var recent_oasis: Oasis = null

var recent_footprints: Array[Vector2] = []

func _ready() -> void:
	reset_state()
	
	WorldManager.player_respawn.connect(_on_respawn_requested)
	
	zone_detector.area_entered.connect(_on_zone_entered)
	zone_detector.area_exited.connect(_on_zone_exited)
	
	shade_detector.area_entered.connect(_on_shade_entered)
	shade_detector.area_exited.connect(_on_shade_exited)
	
	power_up_detector.area_entered.connect(_on_power_up_entered)

func reset_state() -> void:
	current_water = 100.0
	unused_flasks = total_flasks
	in_oasis = 0
	in_shade = 0
	dead = false
	exhausted = false
	idling = false
	last_active_direction = Vector2.DOWN
	speed = 0.0
	
	WorldManager.player_flask_changed.emit(
		unused_flasks,
		total_flasks
	)
	WorldManager.player_water_changed.emit(
		current_water,
		0.0,
		3
	)

func _physics_process(delta: float) -> void:

	if Input.is_action_just_pressed("dev_death"):
		die()
	
	if dead:
		return

	var speed := minf(speed + ACCEL * ACCEL * delta, MAX_SPEED)

	_process_water_drain(delta)

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


func die():
	dead = true
	
	WorldManager.player_died.emit(position)
	Playroom.add_death_location(position, recent_footprints)

func _process_water_drain(delta: float) -> void:
	
	var intensity = -3
	
	if in_oasis > 0:
		intensity = 3
	if in_shade > 0:
		intensity += in_shade
	
	# One flask should recharge in only 2 seconds of oasis time
	const FLASK_RECHARGE_TIME = 100.0 / (2.0 * 3)
	
	# One flask (100.0) should equal roughly 20 seconds of -3 drain
	const DRAIN_TIME_PER_FLASK = 100.0 / (20.0 * 3)
	
	var water_change = delta * DRAIN_TIME_PER_FLASK * intensity
	
	current_water += water_change
	
	# If our water dropped below zero,
	# auto use a flask if available
	if current_water <= 0 and unused_flasks > 0:
		current_water += 100.0
		unused_flasks -= 1
		WorldManager.player_flask_changed.emit(
			unused_flasks,
			total_flasks
		)
	
	# Check if we can recharge flasks while in an oasis
	var empty_flasks = total_flasks - unused_flasks
	if in_oasis > 0 and \
			current_water >= (100.0 + FLASK_RECHARGE_TIME) and \
			empty_flasks > 0:
		unused_flasks += 1
		unused_flasks = mini(unused_flasks, total_flasks)
		current_water = 100.0
		WorldManager.player_flask_changed.emit(
			unused_flasks,
			total_flasks
		)
	elif empty_flasks == 0:
		current_water = minf(current_water, 100.0)
		
	
	# Clamp the water to be within range
	current_water = maxf(current_water, 0.0)
	
	# if our water is still below zero,
	# we died
	if current_water <= 0.0:
		die()
	
	WorldManager.player_water_changed.emit(
		current_water,
		water_change,
		intensity
	)
	
	

func _on_zone_entered(body: Area2D) -> void:
	print("Entered zone: ", body)
	
	if body is Oasis:
		in_oasis += 1
		recent_oasis = body
	
	if in_oasis > 0:
		WorldManager.player_water_changed.emit(
			current_water,
			0.0,
			3
		)


func _on_zone_exited(body: Area2D) -> void:
	print("Exited zone: ", body)
	
	if body is Oasis:
		in_oasis -= 1

func _on_shade_entered(body: Area2D) -> void:
	in_shade += 1
	
func _on_shade_exited(body: Area2D) -> void:
	in_shade -= 1

func _on_power_up_entered(body: Area2D) -> void:
	if body is FlaskPowerUp:
		total_flasks += 1
		unused_flasks += 1
		WorldManager.player_flask_changed.emit(
			unused_flasks,
			total_flasks
		)
		
		body.consume()

func _on_respawn_requested() -> void:
	
	if recent_oasis != null:
		global_position = recent_oasis.player_respawn.global_position
		dead = false



func _anim_place_footprint(spawn_west: bool):
	var footprint = FOOTPRINT.instantiate()
	if spawn_west:
		footprint.global_position = west_side.global_position
	else:
		footprint.global_position = east_side.global_position
	
	get_parent().add_child(footprint)
	
	recent_footprints.push_back(Vector2(footprint.global_position.x, footprint.global_position.y))
	
	while recent_footprints.size() > Playroom.MAX_FOOTPRINTS_STORED:
		recent_footprints.pop_front()
