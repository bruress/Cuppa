extends Area2D

# Parts of hold note
@onready var head = $HeadSprite
@onready var body = $Body
@onready var bottom = $TailSprite

const MISS_WINDOW_PX: float = 30.0		# Miss window after judgment
const END_WINDOW_PX: float = 10.0		# Release window near hold end

var speed: float = 0.0					# Change in rhythm game
var lane_index: int = 0					# Which column

var is_hold: bool = true
var is_being_held: bool = false			# Pressed
var is_finished: bool = false			# Finished
var is_missed: bool = false				# Missed

var judgment_y: float = 0.0

func _process(delta: float) -> void:

	position.y += speed * delta			# Move

	# Holding logic
	if is_being_held:
		var overshoot = position.y - judgment_y		# How much head is compressed
		head.position.y = -overshoot				# Hold head around judgment

		var length_to_decrease = body.size.y - (speed * delta)		# Decrease body
		
		# Body ended
		if length_to_decrease <= 0.0:
			body.size.y = 0
			is_finished = true
		# Body not ended -> decrease
		else:
			body.size.y = length_to_decrease
			body.position.y = head.position.y - body.size.y		# Hold body around judgment/head
			bottom.position.y = body.position.y

	# Not pressed
	elif not is_missed and global_position.y > judgment_y + MISS_WINDOW_PX:
		mark_as_miss()

	var tail_global_y = bottom.global_position.y

	if is_missed and tail_global_y > judgment_y + MISS_WINDOW_PX:
		queue_free()	# Delete
		return
	
	elif is_finished:
		queue_free()	# Delete

## Setup every part of hold note
## [length_px] - duration of hold note in pixels
func setup_hold(length_px: float) -> void:
	var safe_length = max(length_px, 0.0)
	body.size.y = safe_length
	head.position.y = 0
	body.position.y = -safe_length
	bottom.position.y = -safe_length

## Check holding
func start_holding() -> void:
	if not is_missed and not is_finished:
		is_being_held = true

## Stop holding
func stop_holding() -> void:

	# Ignore after miss or finish
	if is_missed or is_finished:
		return

	var tail_global_y = bottom.global_position.y

	# Success
	if tail_global_y >= (judgment_y - END_WINDOW_PX):
		Global.combo = "Bloody bite"
		is_finished = true
		is_being_held = false
	# Early
	else:
		mark_as_miss()

## Mark miss
func mark_as_miss() -> void:
	is_missed = true
	is_being_held = false
	Global.combo = "Miss"
	Global.combo_score = 0

	# Miss animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3)
