extends Node2D

const PLAYER = preload("res://player.tscn")

# Player Name -> Player Object
var player_lookups: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	Playroom.player_joined.connect(_on_player_joined)
	Playroom.player_left.connect(_on_player_left)

func _on_player_joined(room: String, player: String) -> void:
	if player == Playroom.whoami():
		return
	
	if player not in player_lookups:
		print("Player joined the game: ", player)
		var spawn := PLAYER.instantiate() as Player
		spawn.is_remote_player = true
		spawn.remote_player_id = player
		add_child(spawn)
		
		player_lookups[player] = spawn

func _on_player_left(room: String, player: String) -> void:
	
	if player in player_lookups:
		print("Player left the game: ", player)
		player_lookups[player].remote_left()
		player_lookups.erase(player)

