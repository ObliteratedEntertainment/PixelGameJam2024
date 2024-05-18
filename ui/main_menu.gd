extends Control

@onready var menu: CanvasLayer = $Menu
@onready var settings: CanvasLayer = $Settings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu.grab()
	menu.switch_menu.connect(_switch_to_settings)
	settings.switch_menu.connect(_switch_to_main)

func _switch_to_settings() -> void:
	menu.visible = false
	settings.visible = true
	
	settings.grab()

func _switch_to_main() -> void:
	menu.visible = true
	settings.visible = false
	menu.grab()
