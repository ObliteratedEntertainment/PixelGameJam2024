extends CharacterBody2D


const ACCEL := 100.0
const MAX_SPEED := 100.0

var speed := 0.0

func _physics_process(delta: float) -> void:

	var speed := minf(speed + ACCEL * ACCEL * delta, MAX_SPEED)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		speed = maxf(0.0, speed - ACCEL * delta)

	move_and_slide()
