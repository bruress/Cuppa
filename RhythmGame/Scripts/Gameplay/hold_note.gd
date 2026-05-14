extends Area2D

# parts of hold note
@onready var head = $HeadSprite
@onready var body = $Body
@onready var bottom = $TailSprite

const MISS_WINDOW_PX: float = 30.0		# miss window after judgment
const END_WINDOW_PX: float = 10.0		# release window near hold end

var speed: float = 0.0					# change in rhythm game
var lane_index: int = 0					# which column

var is_hold: bool = true
var is_being_held: bool = false			# pressed?
var is_finished: bool = false			# finished?
var is_missed: bool = false				# missed?

var judgment_y: float = 0.0

func _process(delta: float) -> void:

	position.y += speed * delta			# move

	# holding logic
	if is_being_held:
		var overshoot = position.y - judgment_y		# how much head is compressed
		head.position.y = -overshoot				# hold head around judg

		var length_to_decrease = body.size.y - (speed * delta)		# decrease body
		
		# body ended
		if length_to_decrease <= 0.0:
			body.size.y = 0
			is_finished = true
		# body not ended -> decrease
		else:
			body.size.y = length_to_decrease
			body.position.y = head.position.y - body.size.y		# hold body around judg/head
			bottom.position.y = body.position.y

	# not pressed
	elif not is_missed and global_position.y > judgment_y + MISS_WINDOW_PX:
		mark_as_miss()

	var tail_global_y = global_position.y + bottom.position.y

	if is_missed and tail_global_y > judgment_y + MISS_WINDOW_PX:
		queue_free()	# delete
		return
	
	elif is_finished:
		queue_free()	# delete

## setup every part of hold note
## [length_px] - duration of hold note in pixels
func setup_hold(length_px: float) -> void:
	var safe_length = max(length_px, 0.0)
	body.size.y = safe_length
	head.position.y = 0
	body.position.y = -safe_length
	bottom.position.y = -safe_length

## check holding
func start_holding() -> void:
	if not is_missed and not is_finished:
		is_being_held = true

## stop holding
func stop_holding() -> void:

	# ignore after miss or finish
	if is_missed or is_finished:
		return

	var tail_global_y = global_position.y + bottom.position.y

	# success
	if tail_global_y >= (judgment_y - END_WINDOW_PX):
		Global.combo = "Bloody bite"
		is_finished = true
		is_being_held = false
	# early
	else:
		mark_as_miss()

## mark miss
func mark_as_miss() -> void:
	is_missed = true
	is_being_held = false
	Global.combo = "Miss"
	Global.combo_score = 0

	# miss animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3)
