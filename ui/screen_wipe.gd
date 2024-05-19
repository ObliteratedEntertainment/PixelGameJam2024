extends Control

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_waiting_respawn.connect(_on_player_died)
	

func _on_player_died(_pos: Vector2) -> void:
	animation_player.play("FadeOut")

func _anim_fade_out_completed() -> void:
	# Screen is covered, let the player respawn
	WorldManager.player_respawn.emit()
	animation_player.play("FadeIn")
