extends Node2D

const RHYTHM_GAME_SCENE_PATH := "res://Novel/Scenes/MainNovel.tscn"
const SCENE_FADE_TIME := 0.33

var current_line: int = 0
var fade_layer: CanvasLayer
var fade_color: ColorRect

const PROLOGUE_LINES = preload("res://Novel/Data/Dialog/prologue_lines.gd")

var lines: Array = PROLOGUE_LINES.LINES

@onready var role_label: Label = $Role
@onready var dialog_label: Label = $Dialoge
@onready var skip_button: Button = $SkipButton

## Start prologue lines
func _ready() -> void:
	setup_scene_fade()
	show_line()
	skip_button.pressed.connect(skip_prologue)

## Go next by space or click
func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		next_line()
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		next_line()

## Show current line
func show_line() -> void:
	var line: Dictionary = lines[current_line]
	role_label.text = str(line["role"])
	dialog_label.text = str(line["text"])

## Move dialog forward
func next_line() -> void:
	current_line += 1
	if (current_line >= lines.size()):
		skip_prologue()
		return
	show_line()


## Skip prologue
func skip_prologue() -> void:
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
