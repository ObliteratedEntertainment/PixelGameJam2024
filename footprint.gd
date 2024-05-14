extends Sprite2D


func _ready() -> void:
	
	var tween := create_tween()
	
	await tween.tween_property(self, "modulate:a", 0.0, 10.0).finished
	
	queue_free()

