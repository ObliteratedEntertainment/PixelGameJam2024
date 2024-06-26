extends Node

signal ui_active(showing: bool)

signal game_started()
signal game_completed()

signal oasis_entered()
signal oasis_left()

signal zone_left(zone_name: String)
signal zone_entered(zone_name: String)


signal player_died(location: Vector2)
signal player_waiting_respawn()
signal player_respawn()
signal player_idle(active_idle: bool)
signal player_dialog(dialog: bool)

signal player_water_changed(total_water: float, water_delta: float, heat_intensity: int)
signal player_flask_changed(available_flasks: int, total_flasks: int)
signal player_upgraded(upgrade: String)

signal player_started_writing()
signal player_finished_writing(phrase: int, word: int)

var current_zone := ""

# Stats for reporting at the end of the game
var total_water_consumed := 0.0
var total_deaths := 0
var game_start_time := 0
var game_end_time := 0

var player_has_shovel := false
var player_has_flask := false
var player_completed_game := false
var player_total_flasks := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zone_entered.connect(_on_zone_entered)
	player_died.connect(_on_player_death)
	player_water_changed.connect(_on_water_consumed)
	
	game_started.connect(_on_game_start)
	game_completed.connect(_on_game_ended)
	
	player_upgraded.connect(_on_player_upgrade)

func _on_game_start() -> void:
	total_water_consumed = 0
	total_deaths = 0
	game_start_time = Time.get_ticks_msec()

func _on_game_ended() -> void:
	if player_completed_game:
		return
	
	player_completed_game = true
	game_end_time = Time.get_ticks_msec()

func _on_player_upgrade(upgrade: String) -> void:
	if upgrade == Playroom.UPGRADE_FLASK:
		player_has_flask = true
		player_total_flasks += 1
	elif upgrade == Playroom.UPGRADE_SHOVEL:
		player_has_shovel = true

func _on_water_consumed(_total: float, delta: float, _intensity: int) -> void:
	if player_completed_game:
		return
	# consuming water is a negative value
	# regen is positive
	if delta < 0.0:
		total_water_consumed += -1.0 * delta

func _on_zone_entered(zone: String) -> void:
	if current_zone != "":
		zone_left.emit(current_zone)
	
	current_zone = zone

func _on_player_death(_pos: Vector2) -> void:
	if player_completed_game:
		return
	total_deaths += 1
