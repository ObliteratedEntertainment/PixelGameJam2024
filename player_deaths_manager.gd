extends Node2D

const DEAD_PLAYER = preload("res://decorations/dead_player.tscn")

var known_deaths := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Playroom.server_connected.connect(_on_server_connected)
	Playroom.deaths_updated.connect(_on_deaths_updated)
	Playroom.death_load_failed.connect(_on_death_load_failed)
	Playroom.death_loaded.connect(_on_death_loaded)

func _on_server_connected(room: String) -> void:
	# TODO: consider periodically re-requesting this data
	Playroom.request_death_list()

func _on_deaths_updated(room: String, death_list: Array[String]) -> void:
	print("Death list received by manager: ", death_list)
	
	for name in death_list:
		if name not in known_deaths:
			known_deaths[name] = false
	
	# TODO: Find one for now
	for name in known_deaths.keys():
		if not known_deaths[name]:
			known_deaths[name] = true
			Playroom.request_inscription_data(name)
			break

func _on_death_load_failed(room: String, player: String) -> void:
	print("failed to load death for ", room, " and player ", player)

func _on_death_loaded(room: String, player: String, pos: Vector2, footprints: Array[Vector2]) -> void:
	print("Death successfully loaded for ", player)
	print("Position: ", pos)
	print("Footprints: ", footprints)
	
	var body := DEAD_PLAYER.instantiate()
	body.footprints = footprints
	body.offset = pos
	body.position = pos
	add_child(body)
