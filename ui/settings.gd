extends CanvasLayer

signal switch_menu()

@onready var sfx_ui: AudioStreamPlayer = $"SFX UI"

@onready var bgm_level: HSlider = $VBoxContainer/HBoxContainer/BGMLevel
@onready var sfx_level: HSlider = $VBoxContainer/HBoxContainer2/SFXLevel

@onready var accept_selector: Sprite2D = $Accept/AcceptSelector
@onready var bgm_selector: Sprite2D = $VBoxContainer/HBoxContainer/BgmSelector
@onready var sfx_selector: Sprite2D = $VBoxContainer/HBoxContainer2/SfxSelector


@onready var accept: TextureButton = $Accept

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	accept.pressed.connect(_on_accept)
	
	bgm_level.value_changed.connect(_on_volume_changed.bind("BGM"))
	sfx_level.value_changed.connect(_on_volume_changed.bind("SFX"))

	bgm_level.focus_entered.connect(_show_selector.bind(bgm_selector))
	bgm_level.mouse_entered.connect(_show_selector.bind(bgm_selector))
	
	sfx_level.focus_entered.connect(_show_selector.bind(sfx_selector))
	sfx_level.mouse_entered.connect(_show_selector.bind(sfx_selector))
	
	accept.focus_entered.connect(_show_selector.bind(accept_selector))
	accept.mouse_entered.connect(_show_selector.bind(accept_selector))

func grab() -> void:
	bgm_level.grab_focus()

func _on_volume_changed(value: float, bus: String) -> void:
	var bgm_index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bgm_index, linear_to_db(value))

	sfx_ui.play()

func _on_accept() -> void:
	sfx_ui.play()
	switch_menu.emit()

func _show_selector(selector: Sprite2D) -> void:
	selector.visible = true
	sfx_ui.play()
	
	if accept_selector == selector:
		accept.grab_focus()
		sfx_selector.visible = false
		bgm_selector.visible = false
	elif bgm_selector == selector:
		bgm_level.grab_focus()
		sfx_selector.visible = false
		accept_selector.visible = false
	else:
		sfx_level.grab_focus()
		bgm_selector.visible = false
		accept_selector.visible = false
