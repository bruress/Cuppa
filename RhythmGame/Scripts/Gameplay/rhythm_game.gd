extends Node2D

const SM_PARSER = preload("res://RhythmGame/Scripts/Parsing/sm_parser.gd")
const SIDE_LIGHTS_CONTROLLER = preload("res://RhythmGame/Scripts/UI/side_lights_controller.gd")
const SONGS_LIBRARY_DATA = preload("res://RhythmGame/Scripts/State/songs_library.gd")
const POP_UI = preload("res://RhythmGame/Scripts/UI/pop_effect.gd")

@export var songs_library = SONGS_LIBRARY_DATA.SONGS_LIBRARY

@onready var audio = $SongPlayer
@onready var spawns = [$SpawnPoint1, $SpawnPoint2, $SpawnPoint3, $SpawnPoint4]
@onready var light_left: Sprite2D = $LightLeft
@onready var light_right: Sprite2D = $LightRight
@onready var combo_label: Label = $Combo
@onready var combo_score_label: Label = $ComboScore
@onready var combo_text_label: Label = $ComboText

var note_scene = preload("res://RhythmGame/Scenes/Note.tscn")
var hold_scene = preload("res://RhythmGame/Scenes/LongNote.tscn")

const MAX_NOTE_SCORE: int = 10		# Base score per note
const BEATS_TO_TARGET: int = 6		# Travel time in beats (control note speed)
const PROGRESS_SMOOTH_SPEED: float = 3.2
const COMBO_UI_FADE_SPEED: float = 6.0

var bpm: float = 0.0
var beat: float = 0.0
var note_speed: float = 0.0			# (Distance / travel_time)
var travel_time: float = 0.0		# Time to reach judge
var audio_started: bool = false

var game_time: float = 0.0			# Global timer for sync
var is_playing: bool = false		# Pause/stop

var all_notes_data: Array = []
var song_key: String = "crimson_pulse"
var progress_value: float = 100.0
var light_left_base_alpha: float = 0.0
var light_right_base_alpha: float = 0.0
var last_combo_score: int = 0
var combo_ui_alpha: float = 0.0

var side_lights_controller = SIDE_LIGHTS_CONTROLLER.new()
var pop_controller = POP_UI.new()

## Initialize game
func _ready() -> void:
	var data: Dictionary = songs_library[song_key]
	bpm = data["bpm"]
	
	## Math
	beat = 60.0 / bpm
	travel_time = beat * BEATS_TO_TARGET
	var distance: float = abs(spawns[0].global_position.y - $JudgmentRoot.global_position.y)
	note_speed = distance / travel_time

	all_notes_data = SM_PARSER.full_parser(data["path_sm"], beat, data["offset"])		# Parsing

	$ProgressBar.modulate = Color(1.0, 1.0, 1.0, 0.82)
	$ProgressBar.value = 100.0
	light_left_base_alpha = light_left.modulate.a
	light_right_base_alpha = light_right.modulate.a
	start_game(data)

## Start game
## [song_data] - dictionary with all data of songs to take song name
func start_game(song_data: Dictionary) -> void:
	audio.stream = song_data["song"]
	game_time -= travel_time
	is_playing = true
	audio_started = false									# To play music after offset to hit in the beat

## Spawn note
## [lag] - delay with computer draw and current time
## [line_index] - note lane
func spawn_note(lag: float, line_index: int) -> void:
	var note = note_scene.instantiate()
	var spawn_node = spawns[line_index]
	note.global_position = spawn_node.global_position
	note.global_position.y += lag*note_speed
	note.speed = note_speed
	note.line_index = line_index
	add_child(note)

## Spawn hold
## [lag] - delay with computer draw and current time
## [line_index] - hold lane
func spawn_hold_note(lag: float, line_index: int, duration: float) -> void:
	var hold = hold_scene.instantiate()
	var spawn_node = spawns[line_index]
	hold.global_position = spawn_node.global_position
	hold.global_position.y += lag * note_speed
	hold.speed = note_speed
	hold.line_index = line_index
	hold.judgment_y = $JudgmentRoot.global_position.y
	add_child(hold)
	var length = duration * note_speed
	hold.setup_hold(length)
	
## Main game update
func _process(delta: float) -> void:
	update_progress_bar(delta)
	update_ui(delta)

	# Boost background when combo is high
	update_back(delta)
	update_lights(delta)
	update_combo_pop()

	game_time += delta
	var current_sync_time: float = get_current_sync_time()
	spawn_due_notes(current_sync_time)
	try_start_audio()

## Updates score and combo labels
func update_ui(delta: float) -> void:
	$Score.text = str(Global.score)
	combo_text_label.text = Global.combo
	combo_score_label.text = str(Global.combo_score)

	# Smooth show/hide combo UI
	var has_combo: bool = (Global.combo_score > 0)
	var target_alpha: float = 1.0 if has_combo else 0.0
	combo_ui_alpha = lerp(combo_ui_alpha, target_alpha, min(delta * COMBO_UI_FADE_SPEED, 1.0))

	combo_label.visible = true
	combo_text_label.visible = true
	combo_score_label.visible = true
	combo_label.modulate.a = combo_ui_alpha
	combo_text_label.modulate.a = combo_ui_alpha
	combo_score_label.modulate.a = combo_ui_alpha

## Updates background speed and blackout
func update_back(delta) -> void:
	if (Global.combo_score >= 30):
		$BackgroundAnim.speed_scale = lerp($BackgroundAnim.speed_scale, 1.30, min(delta * 4.0, 1.0))
		$BackgroundAnim.modulate = $BackgroundAnim.modulate.lerp(Color(0.75, 0.75, 0.75, 1.0), min(delta * 4.0, 1.0))
	else:
		$BackgroundAnim.speed_scale = lerp($BackgroundAnim.speed_scale, 1.0, min(delta * 4.0, 1.0))
		$BackgroundAnim.modulate = $BackgroundAnim.modulate.lerp(Color(1.0, 1.0, 1.0, 1.0), min(delta * 4.0, 1.0))

## Updates lights
func update_lights(delta) -> void:
	side_lights_controller.update_lights(light_left, light_right, light_left_base_alpha, light_right_base_alpha, game_time, Global.combo_score, delta)

## Updates combo pop effect
func update_combo_pop() -> void:
	# Trigger pop only when combo score really grows
	if (Global.combo_score > last_combo_score):
		pop_controller.pop_label(combo_score_label)
		pop_controller.pop_label(combo_text_label)
	last_combo_score = Global.combo_score

## Returns synchronized song time
func get_current_sync_time() -> float:
	var song_pos: float = 0.0
	if audio.playing:
		song_pos = audio.get_playback_position() + AudioServer.get_time_since_last_mix() 	# Audio_player time + time last update my audio servers
		song_pos -= AudioServer.get_output_latency()		# Minus lag my audio server output
	else:
		song_pos = game_time
	return song_pos

## Spawns notes when their spawn time is reached
func spawn_due_notes(current_sync_time: float) -> void:
	while not all_notes_data.is_empty():
		var note_time = all_notes_data[0].time				# First note in the queue

		if current_sync_time >= (note_time - travel_time):
			var data = all_notes_data.pop_front()			# Delete this note from queue and take it date 
			var lag = current_sync_time - (data.time - travel_time)
			if data.type == "note":
				spawn_note(lag, data.lane)
			elif data.type == "hold":
				spawn_hold_note(lag, data.lane, data.duration)
		else:
			break

## Starts audio once game time
func try_start_audio() -> void:
	if not audio_started and game_time >= 0:
		audio.play()
		audio_started = true

## Stop game
func stop_game() -> void:
	is_playing = false
	audio.stop()

## Manage progress bar 
func update_progress_bar(delta: float) -> void:
	if (Global.judged_count <= 0):
		$ProgressBar.value = 100
		return
	var max_score_so_far: float = float(Global.judged_count * MAX_NOTE_SCORE)
	var accuracy: float = (float(Global.score) / max_score_so_far) * 100.0
	var target_value: float = clamp(accuracy, 0.0, 100.0)
	progress_value = lerp(progress_value, target_value, min(delta * 6.0, 1.0))
	$ProgressBar.value = progress_value
