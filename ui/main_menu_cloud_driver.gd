extends Node2D

@export var speed = 100.0
@export var followers: Array[PathFollow2D] = []


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	for follower in followers:
		follower.progress += delta * speed
