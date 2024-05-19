@tool
extends Node2D

@export var include_base_water := 100.0 : set = _base_set
@export var used_flasks := 0 : set = _flask_set
@export var used_cactus_flowers := 0 : set = _cactus_set
@export var used_digs := 0 : set = _dig_set

@export var display_color := Color.RED : set = _change_color

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if not is_part_of_edited_scene():
		queue_free()
		return
	
	queue_redraw()

func _draw() -> void:
	var circle_size := 80.0 * 20.0 * \
		((include_base_water/100.0) + \
		used_flasks + \
		0.5 * used_digs + \
		0.1 * used_cactus_flowers)
	draw_arc(Vector2.ZERO, circle_size, 0.0, 2*PI, 64, display_color, 8.0)
	
	queue_redraw()

func _change_color(val: Color) -> void:
	display_color = val
	queue_redraw()

func _base_set(val: float) -> void:
	include_base_water = minf(val, 100.0)
	queue_redraw()

func _flask_set(val: int) -> void:
	used_flasks = val
	queue_redraw()

func _cactus_set(val: int) -> void:
	used_cactus_flowers = val
	queue_redraw()

func _dig_set(val: int) -> void:
	used_digs = val
	queue_redraw()
