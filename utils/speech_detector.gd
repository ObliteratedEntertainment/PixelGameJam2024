extends Area2D

@onready var dialog_hint: Sprite2D = $DialogHint
@onready var dialog_box: Sprite2D = $DialogBox

@onready var mumblings: AudioStreamPlayer2D = get_node_or_null("../Mumblings")

@onready var intro_dialogs: Node2D = $DialogBox/IntroDialogs
@onready var challenge_1_done: Node2D = $DialogBox/Challenge1Done
@onready var challenge_2_done: Node2D = $DialogBox/Challenge2Done


var dialog_offset := 0
var seen_all_dialogs := false
var active_dialog_tree: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	dialog_hint.visible = true
	dialog_box.visible = false

	WorldManager.player_upgraded.connect(_on_player_upgrade)
	
	for lbl in dialog_box.get_children():
		lbl.visible = false
	
	active_dialog_tree = intro_dialogs
	active_dialog_tree.visible = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_hint.visible = false
		if dialog_box.visible == false and mumblings != null:
			mumblings.play()
		dialog_box.visible = true
		active_dialog_tree.get_children()[dialog_offset].visible = true
		
func _on_body_exited(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_box.visible = false
		active_dialog_tree.get_children()[dialog_offset].visible = false
		
		dialog_offset += 1
		
		if dialog_offset >= len(active_dialog_tree.get_children()):
			seen_all_dialogs = true
			dialog_offset = 0
		
		dialog_hint.visible = not seen_all_dialogs
		
func _on_player_upgrade(upgrade: String) -> void:
	if upgrade == Playroom.UPGRADE_SHOVEL:
		active_dialog_tree = challenge_1_done
		dialog_offset = 0
		seen_all_dialogs = false
	elif upgrade == Playroom.UPGRADE_FLASK:
		active_dialog_tree = challenge_2_done
		dialog_offset = 0
		seen_all_dialogs = false
		
	# TODO: activate the final dialog tree
	# Need to dynamically insert the player's final stats
