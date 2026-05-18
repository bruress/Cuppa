extends Node2D

const SETTINGS_OVERLAY = preload("res://Menu/Scripts/Settings/settings_overlay.gd")
const RHYTHM_GAME_SCENE_PATH := "res://Novel/Scenes/Prologue.tscn"

const MENU_IDLE_COLOR := Color("#472c2b")
const MENU_HOVER_COLOR := Color("#463438")
const MENU_HOVER_SCALE := Vector2(1.05, 1.05)
const MENU_IDLE_SCALE := Vector2.ONE

var lights: Array[Sprite2D] = []
var base_alphas: Array[float] = []
var ui_tweens: Dictionary = {}

@onready var game_start: Label = $GameStart
@onready var game_settings: Label = $GameSettings
@onready var game_exit: Label = $GameExit

func _ready() -> void:
	cache_lights()
	setup_label(game_start)
	setup_label(game_settings)
	setup_label(game_exit)

## Collect menu lights
func cache_lights() -> void:
	for node in get_children():
		if (String(node.name).begins_with("Light")):
				var sprite := node as Sprite2D
				lights.append(sprite)
				base_alphas.append(sprite.modulate.a)

## Bind hover and click
func setup_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.add_theme_color_override("font_color", MENU_IDLE_COLOR)

	label.mouse_entered.connect(func() -> void:
		label.add_theme_color_override("font_color", MENU_HOVER_COLOR)
		animate_label(label, MENU_HOVER_SCALE, 0.12)
	)
	label.mouse_exited.connect(func() -> void:
		label.add_theme_color_override("font_color", MENU_IDLE_COLOR)
		animate_label(label, MENU_IDLE_SCALE, 0.12)
	)
	label.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_label_pressed(label)
	)

## Handle menu click
func on_label_pressed(label: Label) -> void:
	animate_press(label)
	if label == game_start:
		get_tree().change_scene_to_file(RHYTHM_GAME_SCENE_PATH)
	elif label == game_settings:
		SETTINGS_OVERLAY.open_for(self)
	elif label == game_exit:
		get_tree().quit()

## Smooth label scale
func animate_label(label: Label, target_scale: Vector2, duration: float) -> void:
	var t: Tween = create_tween()
	t.tween_property(label, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Short click pop
func animate_press(label: Label) -> void:
	var t: Tween = create_tween()
	t.tween_property(label, "scale", Vector2(0.97, 0.97), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", MENU_HOVER_SCALE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
