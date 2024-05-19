extends Node2D

const MAX_DEATHS_LOADED = 100

const DEAD_PLAYER = preload("res://decorations/dead_player.tscn")

@onready var death_list_frequency: Timer = $DeathListFrequency
@onready var player_death_frequency: Timer = $PlayerDeathFrequency

var requested_deaths := {}

var queued_requests := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Playroom.server_connected.connect(_on_server_connected)
	Playroom.deaths_updated.connect(_on_deaths_updated)
	Playroom.death_load_failed.connect(_on_death_load_failed)
	Playroom.death_loaded.connect(_on_death_loaded)
	
	death_list_frequency.timeout.connect(_on_server_connected.bind(""))
	player_death_frequency.timeout.connect(_start_next_request)

func _on_server_connected(_room: String) -> void:
	print("[DeathManager] Request full death list from Playroom...")
	Playroom.request_death_list()

func _on_deaths_updated(_room: String, death_list: Array[String]) -> void:
	print("[DeathManager] Death list received: ", death_list)
	
	for key in death_list:
		if key not in requested_deaths:
			requested_deaths[key] = false
	
	queued_requests = {}
	
	# Create a unique set of all the player deaths so we can dedup the info
	var per_player_deaths := {}
	for death_key: String in requested_deaths.keys():
		# skip over any we have already requested previously
		if requested_deaths[death_key]:
			continue
		
		var parts := death_key.split("[")
		
		var player_part := parts[0]
		if player_part not in per_player_deaths:
			per_player_deaths[player_part] = {}
			
		per_player_deaths[player_part][death_key] = true
	
	print("[DeathManager] Unique players found in list: ", len(per_player_deaths))
	
	# From the list of all players, select out a 100 unique deaths
	# Only one death per player
	while len(queued_requests) < MAX_DEATHS_LOADED:
		var players: Array = per_player_deaths.keys()
		if len(players) == 0:
			break
		
		var player_idx := randi_range(0, len(players)-1)
		var player_key: String = players[player_idx]
		
		var player_deaths: Array = per_player_deaths[player_key].keys()
		var death_idx := randi_range(0, len(player_deaths)-1)
		var death_key: String = player_deaths[death_idx]
		
		per_player_deaths.erase(player_key)
		
		queued_requests[death_key] = true
	
	print("[DeathManager] Queued Death Requests: ", queued_requests)


func _on_death_load_failed(room: String, death_key: String) -> void:
	print("[DeathManager] Failed to load death for ", room, " and player ", death_key)

func _on_death_loaded(_room: String, death_key: String, pos: Vector2, footprints: Array[Vector2]) -> void:
	print("[DeathManager] Death successfully loaded for ", death_key)
	
	var body := DEAD_PLAYER.instantiate()
	body.footprints = footprints
	body.offset = pos
	body.position = pos
	add_child(body)

func _start_next_request() -> void:
	
	# Start the request chain with any of the queued ones
	for death_key: String in queued_requests.keys():
		queued_requests.erase(death_key)
		
		if not requested_deaths[death_key]:
			requested_deaths[death_key] = true
			print("[DeathManager] Requesting death for " + death_key)
			Playroom.request_death_data(death_key)
			break
	
	
