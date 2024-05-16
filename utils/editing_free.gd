extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_part_of_edited_scene():
		queue_free()

