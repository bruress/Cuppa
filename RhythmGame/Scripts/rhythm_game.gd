extends Node2D

## Data for all songs
# @export - makes the variable visible in the inspector panel
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

## Variables for convenience
# @onready - handles dependency injection after node initialization
@onready var audio = $Music
@onready var spawns = [$SpawnPoint1, $SpawnPoint2, $SpawnPoint3, $SpawnPoint4]

## Load scenes for future instantiation
var note_scene = preload("res://RhythmGame/Scenes/Note.tscn")
var hold_scene = preload("res://RhythmGame/Scenes/LongNote.tscn")

## CONST
## [MAX_NOTE_SCORE] - base score per note
## [BEATS_TO_TARGET] - travel time in beats (control note speed)
const MAX_NOTE_SCORE: int = 10
const BEATS_TO_TARGET: int = 5

## Note settings
## [bpm] - used for calculating beats, note speed and measures
## [beat] - duration of one beat in second
## [note_speed] - calculated as: (distance/travel_time)
## [travel_time] - time to reach judgment 
## [audio_started] - to control start/stop music
var bpm: float = 0.0
var beat: float = 0.0
var note_speed: float = 0.0
var travel_time: float = 0.0
var audio_started: bool = false

## Game settings
## [game_time] - global timer for sync
## [is_playing] - main game loop toggle
var game_time: float = 0.0
var is_playing: bool = false

## Song settings 
## [all_notes_data] - parsed data for all notes and holds
## [song_key] - to choose current song
var all_notes_data: Array = []
var song_key: String = "bloodroot"

## Initialize game
func _ready():
	## Data initialization
	var data = songs_library[song_key]
	bpm = data["bpm"]
	
	## Math
	beat = 60.0 / bpm
	travel_time = beat * BEATS_TO_TARGET					# calculatte travel time based on rhythm
	var distance = abs(spawns[0].global_position.y - $Judgment.global_position.y)
	note_speed = distance / travel_time
	
	## Functions
	full_parser(data["path_sm"], data["offset"])
	start_order(data)

## Parsing .sm file
## [path] - path to .sm file
## [offset] - audio start offset
func full_parser(path: String, offset: float):
	## Variables
	var current_time = offset								# initial song timestamp
	var holds = {}											# temp for holds
	
	## Prepare to parsing
	all_notes_data.clear()									# clear previous data
	var sm_file = FileAccess.open(path, FileAccess.READ)	# open file for reading
	if not sm_file:
		print("ERROR: Cannot open the file at the path: ", path)
		return
	var content: String = sm_file.get_as_text() 			# read file content as str
	sm_file.close()											# close sm file after reading to optimize system perfomances
	var pos = content.find("0,0,0,0,0:")					# return id "0,0,0,0,0:"
	if pos == -1:
		print("ERROR: File is empty")
	pos+=10													# skip 10 symbols without data notes
	var raw_data = content.substr(pos)						# load only clear text with data notes
	var measures = raw_data.replace(";", " ").split(",")	# split into measures
	
	## Parsing
	## Work with one measure
	for measure in measures:								# take one measure
		var lines = []										# to cleaned note lines
		for i in measure.strip_edges().split("\n"):			# take measure and clear all literals in the end and in the begin and after split at "\n" to get only "0001" for exapmle
			if i.length()==4:								# if it is our 4--lane data
				lines.append(i)								# append it in lines !!! IN THE FUTURE(?) MAKE SKIP COMMENTS IN THE .SM AND MAYBE MORE THEN 4-NOTES LVLS
		var time_per_line = (beat*4.0)/lines.size()			# obviously 1 measure has 4 beats and then we calculate time per line
		
		## Work with line and symbols in it to know notes and holds
		for line in lines:									# every line in lines
			for j in range(4):								# column index
				var symbol = line[j]						# take current symbol to in the future work with it
				match symbol:								# compare
					"1":									# if it's a note
						all_notes_data.append({"time": current_time, "type": "note", "lane": j})
					"2":									# if it's hold start
						holds[j] = current_time				# start time
					"3":									# if it's hold end
						var duration = current_time - holds[j]	# hold time
						all_notes_data.append({"time": holds[j], "type": "hold", "lane": j, "duration": duration})
						holds.erase(j)						# clear old data to new hold
			current_time +=time_per_line					# to know right appearance time of notes

	all_notes_data.sort_custom(func(a, b): return a.time < b.time)	# anonim sort it at time to notes don't appear early then holds which should appear in it this time

## Start game
## [song_data] - dictionary with all data of songs to take song name
func start_order (song_data: Dictionary):
	audio.stream = song_data["song"]						# play current music
	game_time -=travel_time									# play time (beat*my_speed)
	is_playing = true										# game started
	audio_started = false									# to play music after offset to hit in the beat

## Spawn note
## [lag] - delay with computer draw and current time
## [line] - note column
func spawn_note(lag: float, line: int):
	var note = note_scene.instantiate()						# clones note
	var spawn_node = spawns[line]							# take current SpawnPoint
	note.global_position = spawn_node.global_position		# place note at the point
	note.global_position.y += lag*note_speed				# current note position = delay * speed note to lag was not noticeable
	note.speed = note_speed									# passing along speed to note
	note.lane_index = line									# specify lane to note
	add_child(note)											# passing along note in the game

## Spean hold
## [lag] - delay with computer draw and current time
## [line] - hold column
func spawn_hold_note(lag: float, line: int, duration: float):
	var hold = hold_scene.instantiate()						# clones hold
	var spawn_node = spawns[line]							# take current SpawnPoint
	hold.global_position = spawn_node.global_position		# place hold at the point
	hold.global_position.y += lag * note_speed				# current hold position = delay * speed hold to lag was not noticeable

	#add_child(hold) 
	hold.speed = note_speed									# passing along speed to hold
	hold.lane_index = line									# specify lane to hold
	hold.judgment_y = $Judgment.global_position.y			# passing along judg y
	
	add_child(hold) 										# passing along note in the game
	
	# after to appear hold in the scene to call it without any error
	var length = duration * note_speed						# hold lenght = duration * speed (pixel)
	hold.setup_hold(length)									# passing along in hold script 
	
## Perfomances during game
## [delta] - game time after last  frame
func _process(delta):
	var song_data = songs_library[song_key]
	var max_value = song_data["max_value"]
	progress_bar(max_value)
	
	if not is_playing:										# if game doen't started -> stop perfomance
		return

	$Score.text = str(Global.score)							
	$ComboText.text = Global.combo
	$ComboScore.text = str(Global.combo_score)
	
	game_time += delta 										# game time to spawn notes in time
	
	var song_pos = 0.0										# current position in the song
	
	## Find out audio server delay with game
	if audio.playing:										# if song is playing
		song_pos = audio.get_playback_position() + AudioServer.get_time_since_last_mix() # audio_player time + time with last update my audio servers
		song_pos -= AudioServer.get_output_latency()		# minus lag my audio server output
	else:
		song_pos = game_time								# our obiosly secondomer

	var current_sync_time = song_pos						# etalon for out frame

	## Spawn conveyor
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

	if not audio_started and game_time >= 0:				# if audio isn't started and game isn't started too
		audio.play()										# start music
		audio_started = true								# flag is true to don't start it again

## Stop game
func stop_game():
	is_playing = false
	audio.stop()

## Manage progress bar 
## [max_value] - count of notes 
func progress_bar(max_value: int):
	if Global.score>0:										# to don't divide to 0
		var val = 100 - ((float(Global.score) / (max_value*MAX_NOTE_SCORE)) * 100.0)	# decrease progress bar from 100 to decresed score in procent
		var pbar = clamp(val, 0, 100)									# not less then 0, not more then 100
		var tween = create_tween()										# anim
		tween.tween_property($ProgressBar, "value", pbar, 0.3).set_trans(Tween.TRANS_SINE)	# soft translution
