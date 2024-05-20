extends Oasis

@onready var game_over: Area2D = $GameOver

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_over.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		WorldManager.game_completed.emit()
	

