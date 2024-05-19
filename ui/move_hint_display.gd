extends TextureRect

var tweener: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true
	modulate.a = 0
	WorldManager.player_idle.connect(_display_when_idle)

func _display_when_idle(is_idle: bool) -> void:
	
	if is_idle:
		if tweener != null:
			tweener.kill()
		tweener = create_tween()
		tweener.tween_interval(1.5)
		tweener.tween_property(self, "modulate:a", 1.0, 2.5)
	
	else:
		if tweener != null:
			tweener.kill()
		tweener = create_tween()
		tweener.tween_property(self, "modulate:a", 0.0, 0.1)
