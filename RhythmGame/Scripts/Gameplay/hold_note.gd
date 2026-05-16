extends Area2D

signal hold_feedback(hit_color: Color)

# Parts of hold note
@onready var head = $HeadSprite
@onready var body = $Body
@onready var bottom = $TailSprite

const SCORE_SERVICE = preload("res://RhythmGame/Scripts/Controllers/score_service.gd")

const MISS_WINDOW_PX: float = 24.0			# Miss window after judgment

var speed: float = 0.0
var line_index: int = 0

var is_hold: bool = true
var is_being_held: bool = false
var is_finished: bool = false
var is_missed: bool = false
var was_started: bool = false
var was_scored: bool = false

var judgment_y: float = 0.0
var initial_body_length: float = 0.0	# Starting body length

func _process(delta: float) -> void:
	# Move
	position.y += speed * delta

	# Holding logic
	if is_being_held:
		var overshoot = position.y - judgment_y		# How much head is compressed
		head.position.y = lerp(head.position.y, -overshoot, 0.22)	# Hold head around judgment smoothly
		var length_to_decrease: float = max(body.size.y - (speed * delta), 0.0)		# Decrease body

		# Body ended while still holding
		if length_to_decrease <= 0.0:
			body.size.y = 0.0
			apply_hold_result(1.0)
			is_finished = true
			is_being_held = false
		# Body not ended -> decrease
		else:
			body.size.y = length_to_decrease
			body.position.y = head.position.y - body.size.y		# Hold body around judgment/head
			bottom.position.y = body.position.y

	# Not pressed and never started
	elif not is_missed and not was_started and global_position.y > judgment_y + MISS_WINDOW_PX:
		mark_as_miss()

	var tail_global_y = bottom.global_position.y

	# Remove hold only after tail passes judgment zone
	if (is_missed or is_finished or (was_scored and not is_being_held)) and tail_global_y > judgment_y + MISS_WINDOW_PX:
		queue_free()

## Setup every part of hold note
## [length_px] - duration of hold note in pixels
func setup_hold(length_px: float) -> void:
	var safe_length = max(length_px, 0.0)
	initial_body_length = safe_length
	body.size.y = safe_length
	head.position.y = 0
	body.position.y = -safe_length
	bottom.position.y = -safe_length
	was_started = false
	was_scored = false

## Check holding
func start_holding() -> void:
	if not is_missed and not is_finished:
		is_being_held = true
		was_started = true

## Stop holding
func stop_holding() -> void:
	# Ignore after miss or finish
	if is_missed or is_finished:
		return

	is_being_held = false
	apply_hold_result(get_hold_progress())

## Gets hold progress ratio from 0 to 1
func get_hold_progress() -> float:
	if (initial_body_length <= 0.0):
		return 0.0
	var ratio: float = 1.0 - (body.size.y / initial_body_length)
	return clamp(ratio, 0.0, 1.0)

## Applies hold score by hold progress
## [progress] - Current hold progress ratio
func apply_hold_result(progress: float) -> void:
	var result: Dictionary = SCORE_SERVICE.evaluate_hold_progress(progress)
	Global.combo = result["combo_text"]
	Global.score += int(result["score_delta"])
	Global.combo_score += int(result["combo_delta"])
	Global.judged_count += 1
	hold_feedback.emit(result["hit_color"])
	was_scored = true

## Mark miss
func mark_as_miss() -> void:
	is_missed = true
	is_being_held = false
	Global.combo = "Miss"
	Global.combo_score = 0
	Global.judged_count += 1
	hold_feedback.emit(SCORE_SERVICE.MISS_COLOR)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3)
