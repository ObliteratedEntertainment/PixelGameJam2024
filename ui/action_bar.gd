extends HBoxContainer

@onready var dig_hint: TextureRect = $DigHint
@onready var dowse_hint: TextureRect = $DowseHint
@onready var inscribe_hint: TextureRect = $InscribeHint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dig_hint.visible = false
	dowse_hint.visible = false
	WorldManager.player_upgraded.connect(_on_player_upgrade)

func _on_player_upgrade(upgrade: String) -> void:
	if upgrade == Playroom.UPGRADE_SHOVEL:
		dig_hint.visible = true
		dowse_hint.visible = true
