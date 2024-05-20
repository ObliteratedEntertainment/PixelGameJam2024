extends Node2D

const FOOTPRINT = preload("res://footprint.tscn")

@export var player_name: String

@export var offset: Vector2
@export var footprints: Array[Vector2] = []

@onready var label: Label = $Popup/Label
@onready var area_2d: Area2D = $Area2D
@onready var popup: Sprite2D = $Popup

var tween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	label.text = player_name
	popup.visible = false
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	
	# Loaded objects fade into existence rather than popping in
	modulate.a = 0.0
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	var counter := 0.0
	for loc in footprints:
		counter += 1.0
		
		var fp := FOOTPRINT.instantiate()
		fp.auto_tween = false
		fp.position = loc - offset
		fp.modulate = Color(0.0, 0.0, 0.0, counter / (1.0*len(footprints)))
		add_child(fp)
		


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		popup.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player and not body.is_remote_player:
		popup.visible = false
