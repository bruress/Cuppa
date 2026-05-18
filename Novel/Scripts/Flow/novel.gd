extends Node2D

const RHYTHM_GAME_SCENE_PATH := "res://RhythmGame/Scenes/RhythmGame.tscn"
const ENDING_SCENE_PATH := "res://Novel/Scenes/Ending.tscn"
const SCENE_FADE_TIME := 0.33

var current_line: int = 0
var lines: Array = []
var fade_layer: CanvasLayer
var fade_color: ColorRect

const DIALOGS = preload("res://Novel/Data/Dialog/dialogs.gd")

@onready var role_label: Label = $DialogPanel/Role
@onready var dialog_label: Label = $DialogPanel/DialogText
@onready var skip_button: Button = $SkipButton

@onready var mary: AnimatedSprite2D = $Mary
@onready var mary_with_coffee: AnimatedSprite2D = $MaryWithCoffee
@onready var kori: AnimatedSprite2D = $Kori
@onready var kori_with_coffee: AnimatedSprite2D = $KoriWithCoffee
@onready var rose: AnimatedSprite2D = $Rose
@onready var rose_with_coffee: AnimatedSprite2D = $RoseWithCoffee


## Prepare dialog phase
func _ready() -> void:
	setup_scene_fade()
	setup_story_phase()
	show_line()
	skip_button.pressed.connect(skip_scene)

## Go next by space or click
func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		next_line()
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		next_line()

## Pick scene by state
func setup_story_phase() -> void:
	current_line = 0
	set_all_sprites_hidden()

	match Global.novel_state:
		"mary_result":
			mary_with_coffee.visible = true
			if (Global.last_accuracy >= 50.0):
				lines = DIALOGS.LINES["mary_happy"]
				mary_with_coffee.frame = 0
			else:
				lines = DIALOGS.LINES["mary_sad"]
				mary_with_coffee.frame = 0
		"cory_intro":
			kori.visible = true
			kori.frame = 0
			lines = DIALOGS.LINES["cory_intro"]
		"cory_result":
			kori_with_coffee.visible = true
			if (Global.last_accuracy >= 50.0):
				lines = DIALOGS.LINES["cory_happy"]
				kori_with_coffee.frame = 0
			else:
				lines = DIALOGS.LINES["cory_sad"]
				kori_with_coffee.frame = 0
		"rose_intro":
			rose.visible = true
			rose.frame = 0
			lines = DIALOGS.LINES["rose_intro"]
		"rose_result":
			if (Global.bad_results_count >= 2):
				rose_with_coffee.visible = true
				rose_with_coffee.frame = 0
				lines = DIALOGS.LINES["rose_bad_ending"]
				return
			rose_with_coffee.visible = true
			if (Global.last_accuracy >= 50.0):
				lines = DIALOGS.LINES["rose_happy"]
				rose_with_coffee.frame = 0
			else:
				lines = DIALOGS.LINES["rose_sad"]
				rose_with_coffee.frame = 0
		_:
			mary.visible = true
			mary.frame = 0
			lines = DIALOGS.LINES["mary_intro"]

## Hide all character sprites
func set_all_sprites_hidden() -> void:
	mary.visible = false
	mary_with_coffee.visible = false
	kori.visible = false
	kori_with_coffee.visible = false
	rose.visible = false
	rose_with_coffee.visible = false

## Show current line
func show_line() -> void:
	var line: Dictionary = lines[current_line]
	role_label.text = str(line["role"])
	dialog_label.text = str(line["text"])

## Move dialog forward
func next_line() -> void:
	current_line += 1
	if (current_line >= lines.size()):
		skip_scene()
		return
	show_line()

## Route by current novel phase
func skip_scene() -> void:
	match Global.novel_state:
		"mary_intro":
			Global.current_client = "mary"
			switch_scene_with_fade(RHYTHM_GAME_SCENE_PATH)
		"mary_result":
			Global.novel_state = "cory_intro"
			reload_scene_with_fade()
		"cory_intro":
			Global.current_client = "boy"
			switch_scene_with_fade(RHYTHM_GAME_SCENE_PATH)
		"cory_result":
			Global.novel_state = "rose_intro"
			reload_scene_with_fade()
		"rose_intro":
			Global.current_client = "hunter"
			switch_scene_with_fade(RHYTHM_GAME_SCENE_PATH)
		"rose_result":
			Global.novel_state = "mary_intro"
			switch_scene_with_fade(ENDING_SCENE_PATH)
		_:
			Global.current_client = "mary"
			switch_scene_with_fade(RHYTHM_GAME_SCENE_PATH)

## Build fade overlay
func setup_scene_fade() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 200
	add_child(fade_layer)

	fade_color = ColorRect.new()
	fade_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_color.color = Color(0, 0, 0, 0)
	fade_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_color)

## Fade and open scene
## [scene_path] - Target scene path
func switch_scene_with_fade(scene_path: String) -> void:
	var t: Tween = create_tween()
	t.tween_property(fade_color, "color:a", 1.0, SCENE_FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.finished.connect(func() -> void:
		get_tree().change_scene_to_file(scene_path)
	)

## Fade and reload scene
func reload_scene_with_fade() -> void:
	var t: Tween = create_tween()
	t.tween_property(fade_color, "color:a", 1.0, SCENE_FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.finished.connect(func() -> void:
		get_tree().reload_current_scene()
	)
