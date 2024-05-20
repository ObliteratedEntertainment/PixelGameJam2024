extends Area2D
class_name SpeechDetector

@export var fixed_dialog := true
@export var challenge_1_disabled := false
@export var challenge_2_disabled := false

@onready var dialog_hint: Sprite2D = $DialogHint
@onready var dialog_box: Sprite2D = $DialogBox
@onready var dialog_advancekey: Sprite2D = $DialogAdvancekey

@onready var mumblings: AudioStreamPlayer2D = get_node_or_null("../Mumblings")

@onready var intro_dialogs: Node2D = $DialogBox/IntroDialogs
@onready var challenge_1_done: Node2D = $DialogBox/Challenge1Done
@onready var challenge_2_done: Node2D = $DialogBox/Challenge2Done
@onready var game_complete: Node2D = $"../../OldManDeaths/Speech Detector/DialogBox/GameComplete"

var seen_dialogs := {}

var dialog_offset := 0
var seen_all_dialogs := false
var active_dialog_tree: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	dialog_hint.visible = true
	dialog_box.visible = false
	dialog_advancekey.visible = false

	WorldManager.player_upgraded.connect(_on_player_upgrade)
	
	for lbl in dialog_box.get_children():
		lbl.visible = false
	
	active_dialog_tree = intro_dialogs
	active_dialog_tree.visible = true

func advance() -> void:
	active_dialog_tree.get_children()[dialog_offset].visible = false
	
	dialog_offset += 1
	
	if dialog_offset >= len(active_dialog_tree.get_children()):
		seen_all_dialogs = true
		dialog_offset = 0
	
	active_dialog_tree.get_children()[dialog_offset].visible = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_hint.visible = false
		if dialog_box.visible == false and mumblings != null:
			mumblings.play()
		dialog_box.visible = true
		dialog_advancekey.visible = true
		active_dialog_tree.get_children()[dialog_offset].visible = true
		
func _on_body_exited(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		dialog_box.visible = false
		dialog_advancekey.visible = false
		
		advance()
		
		dialog_hint.visible = not seen_all_dialogs
		
func _on_player_upgrade(upgrade: String) -> void:
	if fixed_dialog:
		return
	
	if upgrade == Playroom.UPGRADE_SHOVEL and not challenge_1_disabled:
		active_dialog_tree.visible = false
		active_dialog_tree = challenge_1_done
		active_dialog_tree.visible = true
		dialog_hint.visible = true
		dialog_offset = 0
		seen_all_dialogs = false
	elif upgrade == Playroom.UPGRADE_FLASK and not challenge_2_disabled:
		active_dialog_tree.visible = false
		active_dialog_tree = challenge_2_done
		active_dialog_tree.visible = true
		dialog_hint.visible = true
		dialog_offset = 0
		seen_all_dialogs = false
	elif upgrade == Playroom.UPGRADE_WINNER:
		active_dialog_tree.visible = false
		active_dialog_tree = game_complete
		active_dialog_tree.visible = true
		dialog_hint.visible = true
		dialog_offset = 0
		seen_all_dialogs = false
		
	# TODO: activate the final dialog tree
	# Need to dynamically insert the player's final stats
