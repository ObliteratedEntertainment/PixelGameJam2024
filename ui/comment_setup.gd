extends CanvasLayer

signal switch_menu()

@onready var start_creation: TextureButton = $Explanation/StartCreation

@onready var explanation: TextureRect = $Explanation
@onready var template_select: TextureRect = $TemplateSelect
@onready var noun_select: TextureRect = $NounSelect
@onready var preview: TextureRect = $Preview

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_started_writing.connect(_on_writing)

	start_creation.pressed.connect(_on_start_create)

func _on_writing() -> void:
	WorldManager.ui_active.emit(true)
	visible = true
	
	explanation.visible = true
	template_select.visible = false
	noun_select.visible = false
	preview.visible = false
	
	start_creation.grab_focus()

func _on_start_create() -> void:
	explanation.visible = false
	template_select.visible = true
