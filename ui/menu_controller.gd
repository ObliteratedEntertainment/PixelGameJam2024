extends CanvasLayer

const GAME = preload("res://game.tscn")

signal switch_menu()

@onready var start: TextureButton = $Options/Start
@onready var settings: TextureButton = $Options/Settings

@onready var start_selector: Sprite2D = $Options/Start/Selector2
@onready var settings_selector: Sprite2D = $Options/Settings/Selector

@onready var sfx_ui: AudioStreamPlayer = $"../SFX UI"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grab()
	
	start.focus_entered.connect(_show_selector.bind(start_selector))
	start.mouse_entered.connect(_show_selector.bind(start_selector))
	start.pressed.connect(_on_start)
	
	settings.focus_entered.connect(_show_selector.bind(settings_selector))
	settings.mouse_entered.connect(_show_selector.bind(settings_selector))
	settings.pressed.connect(_on_settings)

func grab() -> void:
	start.grab_focus()

func _on_start() -> void:
	print("Start pressed")
	sfx_ui.play()
	get_tree().change_scene_to_packed(GAME)

func _on_settings() -> void:
	print("Settings pressed")
	sfx_ui.play()
	switch_menu.emit()

func _show_selector(selector: Sprite2D) -> void:
	selector.visible = true
	sfx_ui.play()
	
	if start_selector == selector:
		start.grab_focus()
		settings_selector.visible = false
	else:
		settings.grab_focus()
		start_selector.visible = false
