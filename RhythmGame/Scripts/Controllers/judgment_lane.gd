extends Area2D

@export var assigned_key: note_keys		# Assigned key for this lane
@onready var feedback_sprite = self 	# Sprite used for hit color feedback

# Animation tree for start/hold/end states
@onready var anim_tree: AnimationTree = find_current_anim()

# Shared score rules and colors
const SCORE_SERVICE = preload("res://RhythmGame/Scripts/Controllers/score_service.gd")

# Available lane actions
enum note_keys {S_NOTE, D_NOTE, K_NOTE, L_NOTE}

# Playback handle for lane state machine
var playback: AnimationNodeStateMachinePlayback

# Map enum to input action names
var key_map = {
	note_keys.S_NOTE: "S_NOTE",
	note_keys.D_NOTE: "D_NOTE",
	note_keys.K_NOTE: "K_NOTE",
	note_keys.L_NOTE: "L_NOTE",
}

# State names in animation tree
var s_start: String
var s_hold: String
var s_end: String

# Notes currently inside this judgment area
var notes_in_area: Array[Area2D] = []

var is_pressing: bool = false			# Pressed now
var active_hold_note: Area2D = null		# Active hold note in this lane

## Finds animation tree among lane children
func find_current_anim() -> AnimationTree:
	# Look through children and pick first animation tree
	for child in get_children():
		if child is AnimationTree:
			return child
	return null

## Initializes lane animation state names
func _ready() -> void:
	# Build lane-specific animation state names (Start1/2/3/4)
	var index = str(int(assigned_key)+1)				
	s_start = "Start" + index
	s_hold = "Hold" + index
	s_end = "End" + index
	
	if anim_tree:
		playback = anim_tree.get("parameters/playback")

## Runs lane hold animation while key is pressed
func _process(_delta: float) -> void:
	if is_pressing:
		# Keep hold animation active while key is held
		if playback and playback.get_current_node() != s_hold:
			playback.travel(s_hold)

## Handles lane input press/release events
func _unhandled_input(event: InputEvent) -> void:
	# Get action for this lane
	var action = key_map[assigned_key]
	
	# Key pressed
	if event.is_action_pressed(action):
		# Lane is pressed now
		is_pressing = true
		# Play start animation
		if playback:
			playback.travel(s_start)
		# Try to hit note
		handle_note_hit()
	
	# Key released
	if event.is_action_released(action):
		# Lane is released now
		is_pressing = false
		# Play end animation
		if playback:
			playback.travel(s_end)
		# Send release to hold note
		if active_hold_note:
			break_holding()

## Tries to hit the first note in lane queue
func handle_note_hit() -> void:
	# No notes here
	if notes_in_area.is_empty():
		return

	# Take first note in queue
	var note := notes_in_area[0]

	# Check note type
	var is_hold_note = note.get("is_hold") == true
	if is_hold_note:
		# Save active hold
		active_hold_note = note
		rating(abs(global_position.y - note.global_position.y))
		note.start_holding()
		# Remove processed note
		notes_in_area.remove_at(0)
		return

	# Tap note
	rating(abs(global_position.y - note.global_position.y))
	note.queue_free()
	# Remove processed note
	notes_in_area.remove_at(0)

## Applies score result by distance
## [distance] - Distance between judgment and note
func rating(distance: float) -> void:
	# Get hit result from score rules
	var result: Dictionary = SCORE_SERVICE.evaluate_distance(distance)
	# Update combo text
	Global.combo = result["combo_text"]
	# Add score points for this hit
	Global.score += int(result["score_delta"])
	# Miss resets combo score
	if (Global.combo == "Miss"):
		Global.combo_score = 0
	# Non-miss adds combo score
	else:
		Global.combo_score += int(result["combo_delta"])
	# Paint lane feedback color
	apply_feedback_color(result["hit_color"])

## Colors lane feedback and fades back
## [color] - Color for this hit result
func apply_feedback_color(color: Color) -> void:
	feedback_sprite.modulate = color
	var tween = create_tween()
	tween.tween_property(feedback_sprite, "modulate", Color("f7dcdc"), 0.35).set_trans(Tween.TRANS_SINE)

## Handles key release for active hold
func break_holding() -> void:
	# If hold note still exists, tell it key was released
	if is_instance_valid(active_hold_note):
		active_hold_note.stop_holding()
	# Clear active hold reference in lane
	active_hold_note = null

	
## Handles note enter
## [area] - Entered area
func _on_area_entered(area: Area2D) -> void:
	# Keep only notes from this lane
	if area.is_in_group("notes") and area.get("lane_index") == int(assigned_key):
		# Add note to lane queue
		notes_in_area.append(area)

## Tracks notes leaving area and applies miss when needed
## [area] - Area that exited
func _on_area_exited(area: Area2D) -> void:
	# Ignore unrelated exits
	if not (area in notes_in_area):
		return
	notes_in_area.erase(area)
	# Active hold release is handled in hold note logic
	if area == active_hold_note:
		return
	if area.get("is_finished") == true:
		return
	# Remaining case means a miss
	Global.combo = "Miss"
	Global.combo_score = 0 
		

		
