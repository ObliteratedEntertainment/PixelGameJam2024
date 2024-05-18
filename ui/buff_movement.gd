extends Sprite2D


var tweener: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	tweener = create_tween()
	tweener.parallel().tween_property(self, "position", Vector2.UP * 32, 1.0)
	tweener.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	tweener.tween_callback(queue_free)
