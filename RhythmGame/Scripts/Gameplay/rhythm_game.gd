extends Node2D

const SM_PARSER = preload("res://RhythmGame/Scripts/Parsing/sm_parser.gd")

## Data for all songs
@export var songs_library = {
	"crimson_pulse": {
		"song": preload("res://RhythmGame/Data/Songs/CrimsonPulse.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/CrimsonPulse.sm",
		"bpm": 196.0,
		"offset": -0.020646,
		"max_value": 306
	},
	"velvet_evening": {
		"song":preload("res://RhythmGame/Data/Songs/VelvetEvening.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/VelvetEvening.sm",
		"bpm": 145.0,
		"offset": -0.215708,
		"max_value": 101
	},
	"moonfall": {
		"song":preload("res://RhythmGame/Data/Songs/Moonfall.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/Moonfall.sm",
		"bpm": 184.0,
		"offset": -0.078104,
		"max_value": 314
	},
	"garliss": {
		"song":preload("res://RhythmGame/Data/Songs/Garliss.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/Garliss.sm",
		"bpm": 176.0,
		"offset": -0.316146,
		"max_value": 194
	},
	"night_bloom": {
		"song":preload("res://RhythmGame/Data/Songs/NightBloom.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/NightBloom.sm",
		"bpm": 180.011251,
		"offset":  -0.019917,
		"max_value": 198
	},
	"bloodroot": {
		"song":preload("res://RhythmGame/Data/Songs/Bloodroot.wav"),
		"path_sm": "res://RhythmGame/Data/Songs/Bloodroot.sm",
		"bpm": 160.0,
		"offset": -0.112229,
		"max_value": 226
	}
}

@onready var audio = $SongPlayer
@onready var spawns = [$SpawnPoint1, $SpawnPoint2, $SpawnPoint3, $SpawnPoint4]

## Load scenes
var note_scene = preload("res://RhythmGame/Scenes/Note.tscn")
var hold_scene = preload("res://RhythmGame/Scenes/LongNote.tscn")

const MAX_NOTE_SCORE: int = 10		# base score per note
const BEATS_TO_TARGET: int = 5		# travel time in beats (control note speed)

var bpm: float = 0.0				# beat per minute
var beat: float = 0.0				# beat in second
var note_speed: float = 0.0			# (distance/travel_time)
var travel_time: float = 0.0		# time to reach judge
var audio_started: bool = false		# to control start/stop music

var game_time: float = 0.0			# global timer for sync
var is_playing: bool = false		# pause/stop

var all_notes_data: Array = []		# parsed data for all notes and holds
var song_key: String = "bloodroot"	# to choose current song

## Initialize game
func _ready() -> void:
	var data: Dictionary = songs_library[song_key]
	bpm = data["bpm"]
	
	## Math
	beat = 60.0 / bpm
	travel_time = beat * BEATS_TO_TARGET
	var distance: float = abs(spawns[0].global_position.y - $JudgmentRoot.global_position.y)
	note_speed = distance / travel_time
	
	all_notes_data = SM_PARSER.full_parser(data["path_sm"], beat, data["offset"])
	start_game(data)

## Start game
## [song_data] - dictionary with all data of songs to take song name
func start_game(song_data: Dictionary) -> void:
	audio.stream = song_data["song"]
	game_time -=travel_time
	is_playing = true
	audio_started = false									# to play music after offset to hit in the beat

## Spawn note
## [lag] - delay with computer draw and current time
## [lane_index] - note lane
func spawn_note(lag: float, lane_index: int) -> void:
	var note = note_scene.instantiate()
	var spawn_node = spawns[lane_index]
	note.global_position = spawn_node.global_position
	note.global_position.y += lag*note_speed
	note.speed = note_speed
	note.lane_index = lane_index
	add_child(note)

## Spawn hold
## [lag] - delay with computer draw and current time
## [lane_index] - hold lane
func spawn_hold_note(lag: float, lane_index: int, duration: float) -> void:
	var hold = hold_scene.instantiate()
	var spawn_node = spawns[lane_index]
	hold.global_position = spawn_node.global_position
	hold.global_position.y += lag * note_speed
	hold.speed = note_speed
	hold.lane_index = lane_index
	hold.judgment_y = $JudgmentRoot.global_position.y
	add_child(hold)
	
	# after to appear hold in the scene to call it without any error
	var length = duration * note_speed						# hold lenght = duration * speed (pixel)
	hold.setup_hold(length)
	
## Main game update
func _process(delta: float) -> void:
	var song_data: Dictionary = songs_library[song_key]
	var max_value: int = song_data["max_value"]
	update_progress_bar(max_value)
	
	if not is_playing:
		return

	update_ui()
	game_time += delta
	var current_sync_time: float = get_current_sync_time()
	spawn_due_notes(current_sync_time)
	try_start_audio()

## Updates score and combo labels
func update_ui() -> void:
	$Score.text = str(Global.score)
	$ComboText.text = Global.combo
	$ComboScore.text = str(Global.combo_score)

## Returns synchronized song time
func get_current_sync_time() -> float:
	var song_pos: float = 0.0
	if audio.playing:
		song_pos = audio.get_playback_position() + AudioServer.get_time_since_last_mix() # audio_player time + time with last update my audio servers
		song_pos -= AudioServer.get_output_latency()		# minus lag my audio server output
	else:
		song_pos = game_time
	return song_pos

## Spawns notes when their spawn time is reached
func spawn_due_notes(current_sync_time: float) -> void:
	while not all_notes_data.is_empty():					# while we have notes
		var note_time = all_notes_data[0].time				# time first note in the queue

		if current_sync_time >= (note_time - travel_time):	# if current time >= time_note - time_travel
			var data = all_notes_data.pop_front()			# delete this note from queue and take it date 
			var lag = current_sync_time - (data.time - travel_time) # lag of swapn
			
			if data.type == "note":
				spawn_note(lag, data.lane)
			elif data.type == "hold":
				spawn_hold_note(lag, data.lane, data.duration)
		
		else:												# waiting next frame
			break

## Starts audio once game time reaches zero
func try_start_audio() -> void:
	if not audio_started and game_time >= 0:				# if audio isn't started and game isn't started too
		audio.play()										# start music
		audio_started = true								# flag is true to don't start it again

## Stop game
func stop_game() -> void:
	is_playing = false
	audio.stop()

## Manage progress bar 
## [max_value] - count of notes 
func update_progress_bar(max_value: int) -> void:
	if Global.score>0:
		var val = 100 - ((float(Global.score) / (max_value*MAX_NOTE_SCORE)) * 100.0)
		var pbar = clamp(val, 0, 100)
		var tween = create_tween()
		tween.tween_property($ProgressBar, "value", pbar, 0.3).set_trans(Tween.TRANS_SINE)
