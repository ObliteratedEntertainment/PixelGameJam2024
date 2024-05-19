extends Node2D

const COMMENT = preload("res://decorations/comment.tscn")

var known_inscriptions := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Playroom.server_connected.connect(_on_server_connected)
	Playroom.inscriptions_updated.connect(_on_inscriptions_updated)
	Playroom.inscription_load_failed.connect(_on_inscription_load_failed)
	Playroom.inscription_loaded.connect(_on_inscription_loaded)


func _on_server_connected(room: String) -> void:
	# TODO: consider periodically re-requesting this data
	Playroom.request_inscriptions_list()


func _on_inscriptions_updated(room: String, inscription_list: Array[String]) -> void:
	print("Inscription list received by manager: ", inscription_list)
	
	for name in inscription_list:
		if name not in known_inscriptions:
			known_inscriptions[name] = false
	
	# TODO: Find one for now
	for name in known_inscriptions.keys():
		if not known_inscriptions[name]:
			known_inscriptions[name] = true
			Playroom.request_inscription_data(name)
			break
	
	

func _on_inscription_load_failed(room: String, key: String) -> void:
	print("failed to load inscription for ", room, " and inscription ", key)

func _on_inscription_loaded(room: String, key: String, pos: Vector2, phrase: int, word: int) -> void:
	print("Inscription successfully loaded for ", key)
	print("Position: ", pos)
	print("Comment: ", Comment.create_comment_string(phrase, word))
	
	var comment := COMMENT.instantiate()
	comment.phrase = phrase
	comment.word = word
	comment.position = pos
	add_child(comment)
