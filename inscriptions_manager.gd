extends Node2D

const MAX_COMMENTS_LOADED = 100

const COMMENT = preload("res://decorations/comment.tscn")

@onready var inscription_frequency: Timer = $InscriptionFrequency
@onready var inscription_list_frequency: Timer = $InscriptionListFrequency

var requested_comments := {}

var queued_requests := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Playroom.server_connected.connect(_on_server_connected)
	Playroom.inscriptions_updated.connect(_on_inscriptions_updated)
	Playroom.inscription_load_failed.connect(_on_inscription_load_failed)
	Playroom.inscription_loaded.connect(_on_inscription_loaded)
	
	inscription_list_frequency.timeout.connect(_on_server_connected.bind(""))
	inscription_frequency.timeout.connect(_start_next_request)

func _on_server_connected(_room: String) -> void:
	print("[InscriptionManager] Request full inscription list from Playroom...")
	Playroom.request_inscriptions_list()

func _on_inscriptions_updated(_room: String, inscription_list: Array[String]) -> void:
	print("[InscriptionManager] Inscription list received: ", inscription_list)
	
	for key in inscription_list:
		if key not in requested_comments:
			requested_comments[key] = false
	
	queued_requests = {}
	
	# Create a unique set of all the player comments so we can dedup the info
	var per_player_comments := {}
	for comment_key: String in requested_comments.keys():
		# skip over any we have already requested previously
		if requested_comments[comment_key]:
			continue
		
		var parts := comment_key.split("[")
		
		var player_part := parts[0]
		if player_part not in per_player_comments:
			per_player_comments[player_part] = {}
			
		per_player_comments[player_part][comment_key] = true
	
	print("[InscriptionManager] Unique players found in list: ", len(per_player_comments))
	
	# From the list of all players, select out a 100 unique comments
	# Only one comments per player
	while len(queued_requests) < MAX_COMMENTS_LOADED:
		var players: Array = per_player_comments.keys()
		if len(players) == 0:
			break
		
		var player_idx := randi_range(0, len(players)-1)
		var player_key: String = players[player_idx]
		
		var player_comments: Array = per_player_comments[player_key].keys()
		var comment_idx := randi_range(0, len(player_comments)-1)
		var comment_key: String = player_comments[comment_idx]
		
		per_player_comments.erase(player_key)
		
		queued_requests[comment_key] = true
	
	print("[InscriptionManager] Queued Comment Requests: ", queued_requests)


func _on_inscription_load_failed(room: String, comment_key: String) -> void:
	print("[InscriptionManager] Failed to load comment for ", room, " and player ", comment_key)

func _on_inscription_loaded(_room: String, comment_key: String, pos: Vector2, phrase: int, word: int) -> void:
	print("[InscriptionManager] Comment successfully loaded for ", comment_key, " Comment: ", Comment.create_comment_string(phrase, word))

	var comment := COMMENT.instantiate()
	comment.phrase = phrase
	comment.word = word
	comment.position = pos
	add_child(comment)

func _start_next_request() -> void:
	
	# Start the request chain with any of the queued ones
	for comment_key: String in queued_requests.keys():
		queued_requests.erase(comment_key)
		
		if not requested_comments[comment_key]:
			requested_comments[comment_key] = true
			print("[InscriptionManager] Requesting comment for " + comment_key)
			Playroom.request_inscription_data(comment_key)
			break
