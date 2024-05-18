extends Control

@onready var ui: CanvasLayer = $UI
@onready var settings: CanvasLayer = $Settings


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Add retry logic if the first room is full,
	#  fallback to the next and so on
	if not OS.has_feature("editor"):
		Playroom.connect_room(Playroom.GLOBAL_ROOMS[0])
		
	
	settings.switch_menu.connect(_on_settings_leave)

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("escape_menu"):
		#ui.visible = settings.visible
		settings.visible = not settings.visible
		WorldManager.ui_active.emit(settings.visible)
		if settings.visible:
			settings.grab()

func _on_settings_leave() -> void:
	WorldManager.ui_active.emit(false)
	settings.visible = false
	#ui.visible = true
