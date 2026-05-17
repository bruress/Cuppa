extends Node2D

const LIGHTS_CONTROLLER = preload("res://Menu/Scripts/lights.gd")
const SETTINGS_OVERLAY = preload("res://Menu/Scripts/settings_overlay.gd")
const MENU_LIGHT_TEXTURE_PATH := "res://RhythmGame/Assets/Sprites/Ligths/light.png"
const RHYTHM_GAME_SCENE_PATH := "res://RhythmGame/Scenes/RhythmGame.tscn"

const MENU_IDLE_COLOR := Color(0.2784314, 0.17254902, 0.16862746, 1.0)
const MENU_HOVER_COLOR := Color(0.82, 0.67, 0.70, 1.0)
const MENU_DISABLED_COLOR := Color(0.48, 0.40, 0.40, 1.0)
const MENU_HOVER_SCALE := Vector2(1.05, 1.05)
const MENU_IDLE_SCALE := Vector2.ONE

var lights_controller = LIGHTS_CONTROLLER.new()
var lights: Array[Sprite2D] = []
var base_alphas: Array[float] = []
var ui_tweens: Dictionary = {}

@onready var game_start: Label = $GameStart
@onready var game_continue: Label = $GameContinue
@onready var game_settings: Label = $GameSettings
@onready var game_exit: Label = $GameExit


func _ready() -> void:
	cache_lights()
	setup_menu_actions()


func _process(delta: float) -> void:
	update_lights(delta)


## Collect all menu lights from scene
func cache_lights() -> void:
	lights.clear()
	base_alphas.clear()
	for node in find_children("*", "Sprite2D", true, false):
		var sprite := node as Sprite2D
		if sprite == null:
			continue
		if not is_menu_light(sprite):
			continue
		lights.append(sprite)
		base_alphas.append(sprite.modulate.a)


## Check if sprite is a menu light by texture path
func is_menu_light(sprite: Sprite2D) -> bool:
	if sprite.texture == null:
		return false
	return sprite.texture.resource_path == MENU_LIGHT_TEXTURE_PATH


## Update all lights using shared controller
func update_lights(delta: float) -> void:
	var time_sec: float = Time.get_ticks_msec() / 1000.0
	lights_controller.update_lights(lights, base_alphas, delta, time_sec)


## Bind menu labels to actions and UI feedback
func setup_menu_actions() -> void:
	setup_label(game_start, true)
	setup_label(game_continue, false)
	setup_label(game_settings, true)
	setup_label(game_exit, true)


## Attach hover/click behavior to one label
func setup_label(label: Label, enabled: bool) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.pivot_offset = label.size * 0.5
	label.modulate = MENU_IDLE_COLOR if enabled else MENU_DISABLED_COLOR

	label.mouse_entered.connect(func() -> void:
		if not enabled:
			return
		label.modulate = MENU_HOVER_COLOR
		animate_label(label, MENU_HOVER_SCALE, 0.12)
	)
	label.mouse_exited.connect(func() -> void:
		if not enabled:
			return
		label.modulate = MENU_IDLE_COLOR
		animate_label(label, MENU_IDLE_SCALE, 0.12)
	)
	label.gui_input.connect(func(event: InputEvent) -> void:
		if not enabled:
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_label_pressed(label)
	)


## Handle menu clicks
func on_label_pressed(label: Label) -> void:
	animate_press(label)
	if label == game_start:
		get_tree().change_scene_to_file(RHYTHM_GAME_SCENE_PATH)
	elif label == game_settings:
		SETTINGS_OVERLAY.open_for(self)
	elif label == game_continue:
		print("Continue will be added with saves later.")
	elif label == game_exit:
		get_tree().quit()


## Smooth scale tween for label
func animate_label(label: Label, target_scale: Vector2, duration: float) -> void:
	kill_ui_tween(label)
	var t: Tween = create_tween()
	ui_tweens[label.get_path()] = t
	t.tween_property(label, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Short click pop
func animate_press(label: Label) -> void:
	kill_ui_tween(label)
	var t: Tween = create_tween()
	ui_tweens[label.get_path()] = t
	t.tween_property(label, "scale", Vector2(0.97, 0.97), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", MENU_HOVER_SCALE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Stop previous tween for this label
func kill_ui_tween(label: Label) -> void:
	var key: NodePath = label.get_path()
	if not ui_tweens.has(key):
		return
	var t: Tween = ui_tweens[key]
	if is_instance_valid(t):
		t.kill()
