extends TextureRect

const DECREASING_ARROW = preload("res://ui/decreasing_arrow.tscn")
const INCREASING_ARROW = preload("res://ui/increasing_arrow.tscn")

@onready var display_intensity: HBoxContainer = $HeatIntensity
@onready var color_rect: ColorRect = $ColorRect

var current_intensity := -9999

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	WorldManager.player_water_changed.connect(_on_player_water_change)
	WorldManager.player_flask_changed.connect(_on_player_flasks_changed)
	WorldManager.player_died.connect(_on_player_death)
	
	WorldManager.player_water_changed.emit(0, 0, 3)

func _on_player_death(_location: Vector2) -> void:
	pass

func _on_player_water_change(
	total_water: float,
	water_delta: float,
	heat_intensity: int) -> void:
	
	# Check if intensity changed for arrows
	if current_intensity != heat_intensity:
		current_intensity = heat_intensity
		
		# Clear out the old arrows
		var current_arrows := display_intensity.get_children()
		for arrow in current_arrows:
			display_intensity.remove_child(arrow)
			arrow.queue_free()
		
		var arrow_count = abs(heat_intensity)
		
		# Negative number means HOT
		if heat_intensity < 0:
			for i in range(arrow_count):
				var arrow = DECREASING_ARROW.instantiate()
				display_intensity.add_child(arrow)
		
		# Positive number means we are in an Oasis and regening
		elif heat_intensity > 0:
			for i in range(arrow_count):
				var arrow = INCREASING_ARROW.instantiate()
				display_intensity.add_child(arrow)

	pass
	

func _on_player_flasks_changed(unused: int, total: int) -> void:
	pass
	
	
