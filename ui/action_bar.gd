extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	WorldManager.player_upgraded.connect(_on_player_upgrade)

func _on_player_upgrade(upgrade: String) -> void:
	if upgrade == Playroom.UPGRADE_SHOVEL:
		visible = true
