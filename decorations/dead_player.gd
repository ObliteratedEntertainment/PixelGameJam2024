extends Node2D

const FOOTPRINT = preload("res://footprint.tscn")

@export var offset: Vector2
@export var footprints: Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var counter := 0.0
	for loc in footprints:
		counter += 1.0
		
		var fp := FOOTPRINT.instantiate()
		fp.auto_tween = false
		fp.position = loc - offset
		fp.modulate = Color(0.0, 0.0, 0.0, counter / (1.0*len(footprints)))
		add_child(fp)
		

