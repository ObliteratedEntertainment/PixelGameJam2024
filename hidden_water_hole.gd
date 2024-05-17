extends Area2D
class_name WaterHolePowerUp

@onready var watering_hole_timeout: Timer = $WateringHoleTimeout
@onready var activated: Sprite2D = $Activated

var consumed := false

var tweener: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	watering_hole_timeout.timeout.connect(_on_water_fade)


func consume():
	if consumed:
		return
	
	consumed = true
	
	# show the water active from digging
	activated.visible = true
	
	collision_layer = 0
	watering_hole_timeout.start(3.0)


func _on_water_fade() -> void:

	tweener = create_tween()
	
	tweener.tween_property(self, "modulate:a", 0.0, 1.0)
	tweener.tween_callback(queue_free)
