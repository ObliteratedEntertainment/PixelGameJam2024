extends CanvasLayer

const COMMENT_WORD_BUTTON = preload("res://ui/comment_word_button.tscn")

signal switch_menu()


@onready var start_creation: TextureButton = $Explanation/StartCreation
@onready var finish_create: TextureButton = $Preview/FinishCreate

@onready var phrases: Array[TextureButton] = [
	$TemplateSelect/TemplateOption1,
	$TemplateSelect/TemplateOption2,
	$TemplateSelect/TemplateOption3,
	$TemplateSelect/TemplateOption4,
]

@onready var word_container: HFlowContainer = $NounSelect/NounContainer

@onready var preview_comment: Label = $Preview/PreviewComment

@onready var explanation: TextureRect = $Explanation
@onready var phrase_select: TextureRect = $TemplateSelect
@onready var word_select: TextureRect = $NounSelect
@onready var preview: TextureRect = $Preview


var current_phrase_idx := 0
var current_word_idx := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WorldManager.player_started_writing.connect(_on_writing)

	start_creation.pressed.connect(_on_start_create)
	
	for i in range(len(phrases)):
		phrases[i].pressed.connect(_on_phrase_selected.bind(i))
	
	for i in range(len(Comment.WORD_LIST)):
		var word: String = Comment.WORD_LIST[i]
		var btn_word: CommentWordButton = COMMENT_WORD_BUTTON.instantiate()
		btn_word.word = word
		btn_word.pressed.connect(_on_word_selected.bind(i))
		word_container.add_child(btn_word)
	
	preview.visibility_changed.connect(_on_preview_visible)
	
	finish_create.pressed.connect(_on_finish_create)

func _on_writing() -> void:
	WorldManager.ui_active.emit(true)
	visible = true
	
	explanation.visible = true
	phrase_select.visible = false
	word_select.visible = false
	preview.visible = false
	
	start_creation.grab_focus()

func _on_start_create() -> void:
	explanation.visible = false
	phrase_select.visible = true
	phrases[0].grab_focus()

func _on_phrase_selected(phrase_idx: int) -> void:
	current_phrase_idx = phrase_idx
	
	phrase_select.visible = false
	word_select.visible = true

func _on_word_selected(word_idx: int) -> void:
	current_word_idx = word_idx
	
	word_select.visible = false
	preview.visible = true

func _on_preview_visible() -> void:
	var comment := Comment.create_comment_string(
		current_phrase_idx, 
		current_word_idx
	)

	preview_comment.text = "\"%s\"" % [comment]
		
func _on_finish_create() -> void:
	WorldManager.player_finished_writing.emit(
		current_phrase_idx,
		current_word_idx
	)
	switch_menu.emit()
