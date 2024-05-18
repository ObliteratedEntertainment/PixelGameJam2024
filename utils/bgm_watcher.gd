extends Node2D

@onready var bgm_cross_fader: AnimationPlayer = $BGMCrossFader

var in_oasis := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.oasis_entered.connect(_on_entered_oasis)
	WorldManager.oasis_left.connect(_on_left_oasis)
	


func _on_entered_oasis() -> void:
	if in_oasis:
		return
		
	bgm_cross_fader.play("to_oasis")
	in_oasis = true

func _on_left_oasis() -> void:
	if not in_oasis:
		return
	
	bgm_cross_fader.play("to_desert")
	in_oasis = false
