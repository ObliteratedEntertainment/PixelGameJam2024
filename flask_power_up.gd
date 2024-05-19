extends Area2D
class_name FlaskPowerUp

@onready var flask: Sprite2D = $Flask

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var consumed := false

var tweener: Tween = null

func consume() -> void: 
	if consumed:
		return
	
	consumed = true
	flask.visible = false
	
	collision_layer = 0
	
	_on_fadeout()

func _on_fadeout() -> void:
	if tweener != null:
		tweener.kill()
	tweener = create_tween()
	
	tweener.tween_property(self, "modulate:a", 0.0, 1.0)
