extends Sprite2D

@export var auto_tween := true

func _ready() -> void:
	
	if auto_tween:
		var tween := create_tween()
		
		tween.tween_property(self, "modulate:a", 0.0, 10.0)
		tween.tween_callback(queue_free)

