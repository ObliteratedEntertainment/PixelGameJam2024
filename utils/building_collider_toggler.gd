extends Area2D

@export var keep_out_colliders: Array[CollisionPolygon2D] = []
@export var keep_in_colliders: Array[CollisionPolygon2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Player entered")
		for col in keep_out_colliders:
			col.set_disabled(true)
			
		for col in keep_in_colliders:
			col.set_disabled(false)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		print("Player left")
		for col in keep_out_colliders:
			col.set_disabled(false)
		for col in keep_in_colliders:
			col.set_disabled(true)
