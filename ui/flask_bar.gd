extends HBoxContainer

const EMPTY_FLASK = preload("res://ui/empty_flask.tscn")
const FULL_FLASK = preload("res://ui/full_flask.tscn")

var current_unused := 0
var current_total  := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_flask_changed.connect(
		_on_flasks_changed
	)

func _on_flasks_changed(unused_flasks: int, total_flasks: int) -> void:
	if unused_flasks == current_unused and total_flasks == current_total:
		return
	
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	for i in range(unused_flasks):
		var full_flask := FULL_FLASK.instantiate()
		add_child(full_flask)
	
	for i in range(total_flasks - unused_flasks):
		var empty_flask := EMPTY_FLASK.instantiate()
		add_child(empty_flask)
