extends Node2D
class_name DowsingScanner

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.area_entered.connect(_on_item_detected)


func _on_item_detected(item: Area2D) -> void:
	# Only try to detect invisible items
	# TODO: delay the item showing based on the rate of expansion for the ripple
	if not item.visible:
		item.visible = true


func _anim_ripple_ended() -> void:
	queue_free()
