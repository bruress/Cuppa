extends CanvasLayer
class_name SettingsOverlay

# Paths and defaults
const SETTINGS_SCENE: PackedScene = preload("res://Menu/Scenes/Settings.tscn")
const SETTINGS_SAVE_PATH := "user://settings.json"
const DEFAULT_MUSIC_VOLUME := 0.75
const MUSIC_PLAYER_TYPES: Array[String] = [
	"AudioStreamPlayer",
	"AudioStreamPlayer2D",
]

# Real saved value
static var music_volume: float = DEFAULT_MUSIC_VOLUME
# Temp value before Save
var draft_music_volume: float = DEFAULT_MUSIC_VOLUME

# Ui nodes
@onready var save_button: Button = $Panel/Content/ButtonsRow/SaveButton
@onready var close_button: Button = $Panel/Content/ButtonsRow/CloseButton
@onready var music_slider: HSlider = $Panel/Content/MusicRow/MusicSlider
@onready var music_value_label: Label = $Panel/Content/MusicRow/MusicValue


## Opens settings over current scene.
## [scene_root] - Any node from active scene.
static func open_for(scene_root: Node) -> void:
	var current_scene: Node = scene_root.get_tree().current_scene
	var overlay: Node = SETTINGS_SCENE.instantiate()
	current_scene.add_child(overlay)


## Prepares settings and binds buttons.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_volume = load_saved_volume()
	draft_music_volume = music_volume
	# Prepare slider range and first shown value
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = draft_music_volume
	update_music_label(draft_music_volume)
	# Keep scene volume at saved value until Save
	apply_music_volume(music_volume)
	music_slider.value_changed.connect(on_music_changed)
	save_button.pressed.connect(save_settings)
	close_button.pressed.connect(queue_free)


## Closes settings by Esc.
## [event] - Current input event.
func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		queue_free()


## Updates only temp value while dragging.
## [value] - Slider value 0..1.
func on_music_changed(value: float) -> void:
	draft_music_volume = clamp(value, 0.0, 1.0)
	update_music_label(draft_music_volume)


## Shows readable music percent.
## [value] - Slider value 0..1.
func update_music_label(value: float) -> void:
	var percent: int = int(round(value * 100.0))
	music_value_label.text = str(percent) + "%"


## Applies saved volume to all music players.
## [value] - Real volume 0..1.
func apply_music_volume(value: float) -> void:
	var db: float = linear_to_db(max(value, 0.0001))
	for type_name: String in MUSIC_PLAYER_TYPES:
		for node: Node in get_tree().current_scene.find_children("*", type_name, true, false):
			node.set("volume_db", db)


## Saves draft value and applies it.
func save_settings() -> void:
	music_volume = draft_music_volume
	apply_music_volume(music_volume)
	var file: FileAccess = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	if (file != null):
		file.store_string(JSON.stringify({"music_volume": music_volume}))
	queue_free()


## Loads saved volume from json file.
## Returns value in range 0..1.
func load_saved_volume() -> float:
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH):
		return DEFAULT_MUSIC_VOLUME
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_SAVE_PATH))
	if (parsed is Dictionary and parsed.has("music_volume")):
		return clamp(float(parsed["music_volume"]), 0.0, 1.0)
	return DEFAULT_MUSIC_VOLUME
