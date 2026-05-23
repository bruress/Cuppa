extends Node2D

const MENU_SCENE_PATH := "res://Menu/Scenes/Menu.tscn"
const SCENE_FADE_TIME := 0.33
const ENDING_LINES = preload("res://Novel/Data/Dialog/ending_lines.gd")

@onready var good_layer: Node2D = $GoodEnding
@onready var bad_layer: ColorRect = $BadEnding
@onready var role_label: Label = $Role
@onready var text_label: Label = $DialogText
@onready var continue_button: Button = $ContinueButton

var fade_layer: CanvasLayer
var fade_color: ColorRect
var current_line: int = 0
var lines: Array = []


## Prepare ending by result
func _ready() -> void:
	Global.can_resume = false
	Global.resume_scene_path = ""
	setup_scene_fade()
	setup_ending()
	show_line()
	continue_button.visible = false
	continue_button.pressed.connect(go_to_menu)

## Go next by space or click
func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		next_line()
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		next_line()

## Pick ending variant
func setup_ending() -> void:
	var is_good: bool = Global.bad_results_count < 2
	good_layer.visible = is_good
	bad_layer.visible = not is_good
	current_line = 0

	if is_good:
		lines = ENDING_LINES.GOOD
	else:
		lines = ENDING_LINES.BAD


## Show current ending line
func show_line() -> void:
	if lines.is_empty():
		return
	var line: Dictionary = lines[current_line]
	role_label.text = str(line["role"])
	text_label.text = str(line["text"])


## Move ending dialog forward
func next_line() -> void:
	if lines.is_empty():
		go_to_menu()
		return
	if (current_line >= lines.size() - 1):
		continue_button.visible = true
		return
	current_line += 1
	show_line()


## Return to menu and reset state
func go_to_menu() -> void:
	Global.novel_state = "mary_intro"
	Global.bad_results_count = 0
	switch_scene_with_fade(MENU_SCENE_PATH)


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
