extends StaticBody2D
class_name Cactus

const CACTUS_FLOWER = preload("res://decorations/cactus_flower.tscn")

@onready var flower_spots: Node2D = $FlowerSpots

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_respawn.connect(_respawn_flowers)
	_respawn_flowers()
	
func _respawn_flowers() -> void:
	
	for spot in flower_spots.get_children():
		if spot.get_child_count() > 0:
			continue
		
		var flower = CACTUS_FLOWER.instantiate()
		spot.add_child(flower)
