extends Node2D
class_name Comment

const COMMENTS = [
	preload("res://sprites/comments/comment_4.png"),
	preload("res://sprites/comments/comment_5.png"),
	preload("res://sprites/comments/comment_6.png"),
	preload("res://sprites/comments/comment_2.png"),
]

@onready var sprite_2d: Sprite2D = $Sprite2D

var comment_template := 0
var comment_noun := 0

var tweener: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Comment template determines the appearance
	sprite_2d.texture = COMMENTS[comment_template]

func clear_out() -> void:
	if tweener != null:
		tweener.kill()
	
	var tweener = create_tween()
	tweener.tween_property(self, "modulate:a", 0.0, 0.5)
	tweener.tween_callback(queue_free)
