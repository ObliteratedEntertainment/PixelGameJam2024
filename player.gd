extends CharacterBody2D
class_name Player

const FOOTPRINT = preload("res://footprint.tscn")
const DUG_HOLE = preload("res://dug_hole.tscn")

const ACCEL := 100.0
const MAX_SPEED := 80.0

@export var is_remote_player := false
@export var remote_player_id := ""
@export var remote_old_position := Vector2.ZERO
@export var remote_new_position := Vector2.ZERO
@export var remote_pos_interp := 0.0
@export var remote_time_normalization := 1.0

# indicator if the player's position should be sent out
@export var player_broadcast_ready := true
@export var player_last_broadcast := Vector2.ZERO

@onready var zone_detector: Area2D = $ZoneDetector
@onready var shade_detector: Area2D = $ShadeDetector
@onready var power_up_detector: Area2D = $PowerUpDetector
@onready var broadcast_position_timer: Timer = $BroadcastPositionTimer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


# Spots to drop footprints at
# Can't use left/right foot as its not obvious from animations
@onready var east_side: Marker2D = $EastSide
@onready var west_side: Marker2D = $WestSide

@onready var west_dig: Marker2D = $WestDig
@onready var east_dig: Marker2D = $EastDig



@onready var animation_tree: AnimationTree = $AnimationTree

@onready var sand_step: AudioStreamPlayer2D = $SandFootstep
@onready var grass_step: AudioStreamPlayer2D = $GrassFootstep

@onready var sigh_and_breath: AudioStreamPlayer2D = $SighAndBreath
@onready var last_sigh: AudioStreamPlayer2D = $LastSigh

var speed := MAX_SPEED

var last_active_direction := Vector2.DOWN
@export var idling := false
@export var digging := false
@export var exhausted := false
@export var dead := false
@export var disconnected := false #only applies to remote players

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
	
	broadcast_position_timer.timeout.connect(_on_broadcast_timeout)
	
	zone_detector.area_entered.connect(_on_zone_entered)
	zone_detector.area_exited.connect(_on_zone_exited)
	
	shade_detector.area_entered.connect(_on_shade_entered)
	shade_detector.area_exited.connect(_on_shade_exited)
	
	power_up_detector.area_entered.connect(_on_power_up_entered)

func reset_state() -> void:
	if is_remote_player:
		modulate = Color(0.5, 1.0, 1.0, 0.9)
	
	current_water = 100.0
	unused_flasks = total_flasks
	in_oasis = 0
	in_shade = 0
	dead = false
	exhausted = false
	idling = false
	last_active_direction = Vector2.DOWN
	speed = MAX_SPEED
	
	if not is_remote_player:
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

	# Always calculate water drain while we are alive
	if not is_remote_player:
		_process_water_drain(delta)
	
	# prevent moving while digging
	if digging:
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := _get_player_movement_input(delta)
	
	if direction:
		idling = false
		last_active_direction = direction
		#speed = minf(speed + ACCEL * ACCEL * delta, MAX_SPEED)
		velocity = direction * speed
	else:
		idling = true
		velocity = Vector2.ZERO
		#speed = maxf(0.0, speed - ACCEL * delta)
		
	

	if idling:
		animation_tree["parameters/Idle/Exhausted/blend_position"] = last_active_direction
		animation_tree["parameters/Idle/Idle/blend_position"] = last_active_direction
	else:
		animation_tree["parameters/Movement/blend_position"] = direction
	
	_check_player_actions()

	# Only the local player will move with physics
	if not is_remote_player:
		move_and_slide()

	if not is_remote_player and \
			player_broadcast_ready and \
			not player_last_broadcast.is_equal_approx(position):
		player_broadcast_ready = false
		player_last_broadcast = position
		Playroom.update_my_pos(position)


func _get_player_movement_input(delta: float) -> Vector2:
	if is_remote_player:
		var current_pos := Playroom.get_other_player_position(remote_player_id)
	
		# If we got a real position update
		# start interpolating from the last known spot to this new spot
		if not current_pos.is_equal_approx(remote_new_position):
			player_broadcast_ready = false
			remote_old_position = remote_new_position
			remote_new_position = current_pos
			remote_pos_interp = 0.0
			
			# How long in seconds to get from one spot to the next based on a player's MAX_SPEED
			# delta should be normalized by this to get the right speed
			# normal updates should arrive once a second
			remote_time_normalization = min(1.0, (remote_new_position.distance_to(remote_old_position)) / (MAX_SPEED*0.9))
			
			# if we are too far behind, 
			# snap our position to the beginning of the interp
			if position.distance_squared_to(remote_old_position) > (10.0 * 10.0):
				position = remote_old_position
		
		
		var new_desired_position = lerp(remote_old_position, remote_new_position, remote_pos_interp)
		remote_pos_interp += delta / remote_time_normalization
		remote_pos_interp = minf(remote_pos_interp, 1.0)
		
		# Stop the player's movement (animation)
		# only if they have reached the destination and we know
		# their broadcast should have occurred already
		if position.is_equal_approx(remote_new_position) \
				and player_broadcast_ready:
			return Vector2.ZERO

		# Otherwise update position and point the player in that animated direction
		position = new_desired_position
		return position.direction_to(remote_new_position)
	else:
		var player_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		player_input = player_input.normalized()
		return player_input

func _check_player_actions():
	if is_remote_player:
		# TODO: Update actions to have a location attached to them
		# so we can replay more accurately
		var action = Playroom.get_other_player_action(remote_player_id)
		
		if action == Playroom.ACTION_DIGGING:
			animation_tree["parameters/Digging/blend_position"] = last_active_direction.x
			digging = true
			return
		elif action == Playroom.ACTION_DIED and not dead:
			die()
			return
		elif action == Playroom.ACTION_RESPAWN and dead:
			# TODO: this might be better to do by detecting movement?
			_on_respawn_requested()
			return
		
	else:
		if Input.is_action_just_pressed("player_dig"):
			animation_tree["parameters/Digging/blend_position"] = last_active_direction.x
			digging = true
			Playroom.set_player_action(Playroom.ACTION_DIGGING)
			return

func die():
	dead = true
	
	last_sigh.play()
	
	if not is_remote_player:
		WorldManager.player_died.emit(position)
		Playroom.set_player_action(Playroom.ACTION_DIED)
		Playroom.add_death_location(position, recent_footprints)
	else:
		# do nothing for remote player until they respawn
		pass

func _process_water_drain(delta: float) -> void:
	
	# Start with a base of -3 for the heat burning you
	var intensity = -3
	
	if in_oasis > 0:
		intensity = 3
	
	# Add booster from being in the shade
	intensity += in_shade
	
	# If we are outside the oasis
	# don't allow shade boosting to make us positive (healing)
	if in_oasis <= 0:
		# outside of an oasis you can't heal so no positive values allowed
		intensity = min(0, intensity)
	
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
	
	if int(current_water) < 100 && int(current_water) % 20 == 0 && !sigh_and_breath.playing:
		sigh_and_breath.play()
	
	# if our water is still below zero,
	# we died
	if current_water <= 0.0:
		die()
	
	WorldManager.player_water_changed.emit(
		current_water,
		water_change,
		intensity
	)
	
func _on_broadcast_timeout() -> void:
	player_broadcast_ready = true

func _on_zone_entered(body: Area2D) -> void:
	if is_remote_player:
		return
		
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
	if is_remote_player:
		return
	
	print("Exited zone: ", body)
	
	if body is Oasis:
		in_oasis -= 1

func _on_shade_entered(body: Area2D) -> void:
	if is_remote_player:
		return
		
	if body is ShadeValue:
		in_shade += body.shade_value
	else:
		in_shade += 1
	
func _on_shade_exited(body: Area2D) -> void:
	if is_remote_player:
		return
		
	if body is ShadeValue:
		in_shade -= body.shade_value
	else:
		in_shade -= 1

func _on_power_up_entered(body: Area2D) -> void:
	if is_remote_player:
		return
	
	if body is FlaskPowerUp and not body.consumed:
		total_flasks += 1
		unused_flasks += 1
		WorldManager.player_flask_changed.emit(
			unused_flasks,
			total_flasks
		)
		
		body.consume()

func _on_respawn_requested() -> void:
	if is_remote_player:
		return
	
	if recent_oasis != null:
		global_position = recent_oasis.player_respawn.global_position
		dead = false

func _anim_dig_hole(spawn_west: bool):
	Playroom.set_player_action(Playroom.ACTION_NONE)
	
	var hole = DUG_HOLE.instantiate()
	if spawn_west:
		hole.global_position = west_dig.global_position
	else:
		hole.global_position = east_dig.global_position

	get_parent().add_child(hole)

func _anim_place_footprint(spawn_west: bool):
	var spawn_point = Vector2.ZERO
	if spawn_west:
		spawn_point = west_side.global_position
	else:
		spawn_point = east_side.global_position
	
	# check if this footprint is too close to the other
	const TOO_CLOSE_FOOTPRINT = 10.0 # world coord distance
	if len(recent_footprints) > 0 and \
			spawn_point.distance_to(recent_footprints.back()) < TOO_CLOSE_FOOTPRINT:
		return
	
	var footprint = FOOTPRINT.instantiate()
	footprint.global_position = spawn_point
	get_parent().add_child(footprint)
	
	if in_oasis > 0:
		grass_step.play()
	else:
		sand_step.play()
	
	recent_footprints.push_back(Vector2(footprint.global_position.x, footprint.global_position.y))
	
	while recent_footprints.size() > Playroom.MAX_FOOTPRINTS_STORED:
		recent_footprints.pop_front()

func _anim_player_freed() -> void:
	get_parent().remove_child(self)
	queue_free()
