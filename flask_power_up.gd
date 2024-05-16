extends Area2D
class_name FlaskPowerUp

@onready var flask: Sprite2D = $Flask

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var consumed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func consume(): 
	if consumed:
		return
	
	consumed = true
	flask.visible = false
	
	# TODO: call animation player to do a power removal
	visible = false
