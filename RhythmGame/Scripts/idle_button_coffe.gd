extends Area2D

## Assigned to each area their key
@export var assigned_key: note_keys

## Note effect to combo
@onready var feedback_sprite = self 

## Link to node with animation
@onready var anim_tree: AnimationTree = find_current_anim()

## Dictionary of keys
enum note_keys {S_NOTE, D_NOTE, K_NOTE, L_NOTE}

## To control "Start->Hold->End"
var playback: AnimationNodeStateMachinePlayback

## Connect my variables with Godot settings
var key_map = {
	note_keys.S_NOTE: "S_NOTE",
	note_keys.D_NOTE: "D_NOTE",
	note_keys.K_NOTE: "K_NOTE",
	note_keys.L_NOTE: "L_NOTE",
}

## Variables of animations
var s_start: String
var s_hold: String
var s_end: String

## All notes in area of judg
var notes_in_area: Array = []

## Variables to manage holds
var is_pressing: bool = false
var active_hold_note = null

## Find anim by area
func find_current_anim() -> AnimationTree:
	for child in get_children():						# take all children of area
		if child is AnimationTree:						# if child is an anim
			return child								# we get it!
	return null											# or no :(

## Initialize because I start anim with "start1" and e.t.c.
func _ready():
	var index = str(int(assigned_key)+1)				
	s_start = "Start" + index
	s_hold = "Hold" + index
	s_end = "End" + index
	
	if anim_tree:										# if anim exists
		playback = anim_tree.get("parameters/playback")	# to switch anim instatly with help of AnimationNodeStateMachinePlayback

## To pressing call anim "Hold[index] all this time
## [delta] - game time after last  frame
func _process(_delta):
	if is_pressing:
		if playback.get_current_node() != s_hold:		# if current anim isn't "Hold[index]"
			playback.travel(s_hold)						# switch to "Hold[index]"
		
		if active_hold_note and is_instance_valid(active_hold_note):	# we pressing hold note and hold note is alive: is_finished from "long_note"?
			if active_hold_note.get("is_finished"):						# it's end of hold?
				finish_holding()

## Press key == action
func _unhandled_input(event):
	var action = key_map[assigned_key]					# what key it is
	
	if event.is_action_pressed(action):					# triggers once at press
		is_pressing = true
		if playback: playback.travel(s_start)			# start animation "Start[index]"
		handle_note_hit()								# ???????
	
	if event.is_action_released(action):				# triggers once at release
		is_pressing = false
		if playback: playback.travel(s_end)				# start animation "End[index]"
		if active_hold_note:
			break_holding()

## Manage hits
func handle_note_hit():
	if not notes_in_area.is_empty():					# notes around judg?
		var note = notes_in_area[0]						# take first note
		if not is_instance_valid(note): 				# but if it note already dies - remove it
			notes_in_area.remove_at(0)					
			return

		var is_hold = note.get("is_hold") == true		# is hold?
		if is_hold:
			active_hold_note = note
			CalculateHold(note)
			notes_in_area.erase(note)
		else:
			CalculateScore(note)
			notes_in_area.remove_at(0)
			
## Calculate points for ordinary notes upon hit
## [note] - note
func CalculateScore(note):
	rating(abs(global_position.y - note.global_position.y))
	note.queue_free()

## Calculate points for hold upon key hold
## [note] - hold
func CalculateHold(note):
	rating(abs(global_position.y - note.global_position.y))
	note.start_holding()
	
## UI, combo, score, combo_score
## [distance] - difference between judg and note
func rating(distance: float):
	var hit_color = Color("f7dcdc")
	if distance < 50: 
		Global.combo_score += 10
		Global.combo = "Bloody bite"
		Global.score += 10
		hit_color = Color(1.0, 0.0, 0.318, 1.0)
	elif distance < 80: 
		Global.combo_score += 10
		Global.combo = "Bloody"
		Global.score += 5
		hit_color = Color(1.0, 0.664, 0.531, 1.0)
	elif distance < 110: 
		Global.combo_score += 10
		Global.combo = "Lame"
		Global.score += 1
		hit_color = Color(0.336, 0.782, 0.878, 1.0)
	else: 
		Global.combo = "Miss"
		hit_color = Color(0.125, 0.072, 0.146, 1.0)
		Global.combo_score = 0 
	apply_feedback_color(hit_color)

## Coloring of the grade
## [color] - litrally color
func apply_feedback_color(color: Color):
	feedback_sprite.modulate = color					# apply color
	var tween = create_tween()							# create anim
	tween.tween_property(feedback_sprite, "modulate", Color("f7dcdc"), 0.35).set_trans(Tween.TRANS_SINE)

## Success hold - delete hold
func finish_holding():
	if is_instance_valid(active_hold_note):
		active_hold_note.queue_free()
	active_hold_note = null

## Not success hold - coloring and not active
func break_holding():
	if is_instance_valid(active_hold_note):
		active_hold_note.mark_as_miss() 
		active_hold_note.is_being_held = false 
	active_hold_note = null
	Global.combo = "Miss"
	Global.combo_score = 0 

	
func _on_area_entered(area):
	if area.is_in_group("notes") and area.get("column_index") == int(assigned_key):
		notes_in_area.append(area)

func _on_area_exited(area):
	if area in notes_in_area:
		notes_in_area.erase(area)
		Global.combo = "Miss"
		Global.combo_score = 0 
		

		
