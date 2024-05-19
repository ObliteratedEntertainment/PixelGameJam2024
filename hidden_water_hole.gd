extends Area2D
class_name WaterHolePowerUp

@onready var watering_hole_timeout: Timer = $WateringHoleTimeout
@onready var activated: Sprite2D = $Activated

var consumed := false

var tweener: Tween = null

var original_collision_layer := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	original_collision_layer = collision_layer
	watering_hole_timeout.timeout.connect(_on_water_fade)
	
	WorldManager.player_respawn.connect(_on_player_respawn)


func consume() -> void:
	if consumed:
		return
	
	consumed = true
	
	# show the water active from digging
	visible = true
	activated.visible = true
	
	collision_layer = 0
	watering_hole_timeout.start(3.0)

func _on_player_respawn() -> void:
	# when the player has died, then respawns
	# reset everything
	visible = false
	consumed = false
	activated.visible = false
	modulate.a = 1.0
	collision_layer = original_collision_layer

func _on_water_fade() -> void:
	if tweener != null:
		tweener.kill()
	tweener = create_tween()
	
	tweener.tween_property(self, "modulate:a", 0.0, 1.0)

