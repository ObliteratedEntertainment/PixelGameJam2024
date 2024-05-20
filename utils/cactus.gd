extends StaticBody2D
class_name Cactus

const CACTUS_FLOWER = preload("res://decorations/cactus_flower.tscn")

@onready var flower_spots: Node2D = $FlowerSpots

var consumed := false

var flowers: Array[Node2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_respawn.connect(_respawn_flowers)
	_respawn_flowers()
	
func consume() -> int:
	if consumed:
		return 0
	
	consumed = true
	
	var flowers = _clear_flowers()
	
	return flowers

func _clear_flowers() -> int:
	var flower_count := 0
	for spot in flower_spots.get_children():
		# Clear out any old stuff
		for child in spot.get_children():
			spot.remove_child(child)
			flower_count += 1
	
	return flower_count

func _respawn_flowers() -> void:
	consumed = false
	
	_clear_flowers()
	
	for spot in flower_spots.get_children():
		
		var flower := CACTUS_FLOWER.instantiate()
		spot.add_child(flower)
