extends Node

signal zone_left(zone_name: String)
signal zone_entered(zone_name: String)

signal player_died(location: Vector2)
signal player_respawn()

signal player_water_changed(total_water: float, water_delta: float, heat_intensity: int)
signal player_flask_changed(available_flasks: int, total_flasks: int)

var current_zone := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zone_entered.connect(_on_zone_entered)


func _on_zone_entered(zone: String) -> void:
	if current_zone != "":
		zone_left.emit(current_zone)
	
	current_zone = zone
