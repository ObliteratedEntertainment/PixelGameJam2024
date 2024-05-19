extends Node2D
class_name DowsingScanner

@onready var max_detection: Area2D = $MaxDetection

var per_item_tweens: Dictionary = {}

var ripple_tween: Tween = null

func _ready() -> void:
	max_detection.area_entered.connect(_on_item_detected)


func _on_item_detected(item: Area2D) -> void:
	# Only try to detect invisible items
	if not item.visible:
		if item in per_item_tweens:
			per_item_tweens[item].kill()
			
		var tween := get_tree().create_tween()
		var dist_to_center := global_position.distance_to(item.global_position)
		var time_lag := dist_to_center / 40.0 # determined empirically
		tween.tween_property(item, "visible", true, time_lag)
		per_item_tweens[item] = tween


func _anim_ripple_ended() -> void:
	queue_free()
