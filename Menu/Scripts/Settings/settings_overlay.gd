extends CanvasLayer
class_name SettingsOverlay

const SETTINGS_SCENE: PackedScene = preload("res://Menu/Scenes/Settings.tscn")
const DEFAULT_MUSIC_VOLUME := 0.75
const MASTER_BUS := "Master"

static var music_volume: float = DEFAULT_MUSIC_VOLUME		# Real saved value
var draft_music_volume: float = DEFAULT_MUSIC_VOLUME		# Temp value before save

@onready var save_button: Button = $Panel/Content/ButtonsRow/SaveButton
@onready var close_button: Button = $Panel/Content/ButtonsRow/CloseButton
@onready var music_slider: HSlider = $Panel/Content/MusicRow/MusicSlider
@onready var music_value_label: Label = $Panel/Content/MusicRow/MusicValue


## Open settings over current scene
## [scene_root] - Any node from active scene
static func open_for(scene_root: Node) -> void:
	var current_scene: Node = scene_root.get_tree().current_scene
	var overlay: Node = SETTINGS_SCENE.instantiate()
	current_scene.add_child(overlay)

## Prepare settings and bind buttons
func _ready() -> void:
	draft_music_volume = music_volume
	music_slider.value = draft_music_volume

	update_music_label(draft_music_volume)
	apply_music_volume(music_volume)
	
	music_slider.value_changed.connect(on_music_changed)
	save_button.pressed.connect(save_settings)
	close_button.pressed.connect(queue_free)

## Close by Esc
func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel")):
		queue_free()

## Update temp value while dragging
## [value] - Slider value 0..1
func on_music_changed(value: float) -> void:
	draft_music_volume = clamp(value, 0.0, 1.0)
	update_music_label(draft_music_volume)

## Show music percent
## [value] - Slider value 0..1
func update_music_label(value: float) -> void:
	var percent: int = int(round(value * 100.0))
	music_value_label.text = str(percent) + "%"

## Apply saved volume
## [value] - Volume
func apply_music_volume(value: float) -> void:
	var db: float = linear_to_db(max(value, 0.0001))
	var bus_index: int = AudioServer.get_bus_index(MASTER_BUS)
	if (bus_index >= 0):
		AudioServer.set_bus_volume_db(bus_index, db)
	for node: Node in get_tree().current_scene.find_children("*", "AudioStreamPlayer2D", true, false):
		node.set("volume_db", db)

## Save draft value and apply it
func save_settings() -> void:
	music_volume = draft_music_volume
	apply_music_volume(music_volume)
	queue_free()
