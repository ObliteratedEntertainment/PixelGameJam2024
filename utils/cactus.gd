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
	consumed = true
	print("Player ate cactus")
	
	for flower in flowers:
		flower.get_parent().remove_child(flower)
	
	return len(flowers)
	
func _respawn_flowers() -> void:
	consumed = false
	flowers = []
	
	for spot in flower_spots.get_children():
		if spot.get_child_count() > 0:
			continue
		
		var flower := CACTUS_FLOWER.instantiate()
		spot.add_child(flower)
		flowers.push_back(flower)
