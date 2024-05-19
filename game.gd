extends Control

@onready var ui: CanvasLayer = $UI
@onready var settings: CanvasLayer = $Settings

@onready var comment_setup: CanvasLayer = $CommentSetup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: Add retry logic if the first room is full,
	#  fallback to the next and so on
	if not OS.has_feature("editor"):
		Playroom.connect_room(Playroom.GLOBAL_ROOMS[0])
	
	settings.visible = false
	comment_setup.visible = false
	
	settings.switch_menu.connect(_on_settings_leave)
	comment_setup.switch_menu.connect(_on_comment_finished)

func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("escape_menu"):
		
		if comment_setup.visible:
			comment_setup.visible = false
		else:
			settings.visible = not settings.visible
			
		WorldManager.ui_active.emit(settings.visible)
		if settings.visible:
			settings.grab()

func _on_settings_leave() -> void:
	WorldManager.ui_active.emit(false)
	settings.visible = false
	#ui.visible = true

func _on_comment_finished() -> void:
	WorldManager.ui_active.emit(false)
	comment_setup.visible = false
	
