extends Area2D

@onready var dialog_hint: Sprite2D = $DialogHint
@onready var dialog_box: Sprite2D = $DialogBox

@onready var mumblings: AudioStreamPlayer2D = get_node_or_null("../Mumblings")

var dialog_offset := 0
var seen_all_dialogs := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	dialog_hint.visible = true
	dialog_box.visible = false
	
	for lbl in dialog_box.get_children():
		lbl.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_hint.visible = false
		if dialog_box.visible == false and mumblings != null:
			mumblings.play()
		dialog_box.visible = true
		dialog_box.get_children()[dialog_offset].visible = true
		
func _on_body_exited(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_box.visible = false
		dialog_box.get_children()[dialog_offset].visible = false
		
		dialog_offset += 1
		
		if dialog_offset >= len(dialog_box.get_children()):
			seen_all_dialogs = true
			dialog_offset = 0
		
		dialog_hint.visible = not seen_all_dialogs
		
