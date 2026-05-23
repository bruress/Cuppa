extends CanvasLayer
class_name PauseOverlay

const SETTINGS_OVERLAY = preload("res://Menu/Scripts/Settings/settings_overlay.gd")
const MENU_SCENE_PATH := "res://Menu/Scenes/Menu.tscn"
const OVERLAY_SCENE: PackedScene = preload("res://Menu/Scenes/PauseOverlay.tscn")

@onready var continue_button: Button = $Panel/Content/Buttons/ContinueButton
@onready var settings_button: Button = $Panel/Content/Buttons/SettingsButton
@onready var menu_button: Button = $Panel/Content/Buttons/MenuButton
@onready var exit_button: Button = $Panel/Content/Buttons/ExitButton

var resume_scene_path: String = ""
var is_closing: bool = false

## Open pause overlay over current scene
## [scene_root] - Any node from active scene
## [scene_path] - Path used by menu "Continue"
static func open_for(scene_root: Node, scene_path: String) -> void:
	var current_scene: Node = scene_root.get_tree().current_scene
	if current_scene.get_node_or_null("PauseOverlay") != null:
		return
	var overlay: PauseOverlay = OVERLAY_SCENE.instantiate()
	overlay.resume_scene_path = scene_path
	current_scene.add_child(overlay)
	current_scene.get_tree().paused = true

## Bind pause menu actions
func _ready() -> void:
	continue_button.pressed.connect(resume_game)
	settings_button.pressed.connect(open_settings)
	menu_button.pressed.connect(return_to_menu)
	exit_button.pressed.connect(exit_game)
	continue_button.grab_focus()

## Close by Esc
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		resume_game()

## Resume paused scene
func resume_game() -> void:
	if is_closing:
		return
	is_closing = true
	get_tree().paused = false
	queue_free()

## Open settings on top of pause overlay
func open_settings() -> void:
	var overlay: SettingsOverlay = SETTINGS_OVERLAY.open_for(self)
	if overlay != null:
		overlay.layer = max(layer + 1, overlay.layer)

## Go back to menu and keep runtime resume path
func return_to_menu() -> void:
	if is_closing:
		return
	is_closing = true
	Global.can_resume = not resume_scene_path.is_empty()
	Global.resume_scene_path = resume_scene_path
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE_PATH)

## Exit application
func exit_game() -> void:
	if is_closing:
		return
	is_closing = true
	get_tree().paused = false
	get_tree().quit()
