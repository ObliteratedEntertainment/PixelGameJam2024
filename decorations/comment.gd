extends Node2D
class_name Comment

const PHRASE_LIST := [
	"PRAISE",
	"BEWARE",
	"TRY",
	"NEED"
]

const WORD_LIST := [
	"AQUA",
	"FRIEND",
	
	"HERE",
	"NORTH",
	"SOUTH",
	"EAST",
	"WEST",
	"AGAIN",
	
	"FLASK",
	"CACTUS",
	"THIRST",
	"SUN",
	"SHOVEL",
	"DIG",
	"SCAN",
	"HOLE",
	"CLOUD",
	"SHADE",
	"OASIS",
	"PATH",
	"DEATH",
]

const COMMENTS = [
	preload("res://sprites/comments/comment_4.png"),
	preload("res://sprites/comments/comment_5.png"),
	preload("res://sprites/comments/comment_7.png"),
	preload("res://sprites/comments/comment_2.png"),
]

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Popup/Label
@onready var area_2d: Area2D = $Area2D
@onready var popup: Sprite2D = $Popup

@export var phrase := 0
@export var word := 0

var tweener: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if phrase >= len(PHRASE_LIST):
		phrase = 0
	if word >= len(WORD_LIST):
		word = 0
	
	# Loaded objects fade into existence rather than popping in
	modulate.a = 0.0
	tweener = create_tween()
	tweener.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Comment phrase determines the appearance
	sprite_2d.texture = COMMENTS[phrase]
	
	popup.visible = false
	
	label.text = Comment.create_comment_string(phrase, word)
	
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

static func create_comment_string(comment_phrase: int, comment_word: int) -> String:
	return "%s %s" % [
		PHRASE_LIST[comment_phrase],
		WORD_LIST[comment_word]
	]

func clear_out() -> void:
	if tweener != null:
		tweener.kill()
	
	tweener = create_tween()
	tweener.tween_property(self, "modulate:a", 0.0, 0.5)
	tweener.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		popup.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		popup.visible = false
	
