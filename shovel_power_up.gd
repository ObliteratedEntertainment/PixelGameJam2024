extends Area2D
class_name ShovelPowerUp

@onready var shovel: Sprite2D = $Shovel

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var consumed := false

var tweener: Tween = null

func consume(): 
	if consumed:
		return
	
	consumed = true
	shovel.visible = false
	
	collision_layer = 0
	
	_on_fadeout()

func _on_fadeout() -> void:
	if tweener != null:
		tweener.kill()
	tweener = create_tween()
	
	tweener.tween_property(self, "modulate:a", 0.0, 1.0)
