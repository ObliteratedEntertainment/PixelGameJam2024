extends Sprite2D

@export var travel_distance = 1600.0
@export var travel_time = 120.0

var initial_position: Vector2 = Vector2.ZERO

var tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_position = position
	
	reset()

func reset():
	if tween != null:
		tween.kill()
	
	position = initial_position
	modulate.a = 1.0
	
	tween = create_tween()
	
	tween.tween_property(self, "position", position + Vector2.LEFT* travel_distance, travel_time )
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(reset)
