extends Area2D

## Variables to convenient it and injects after init
@onready var head = $HeadNote
@onready var body = $BodyNote
@onready var bottom = $BottomNote

## Variables for each note
var speed: float = 0.0				# changed in rhythm game
var column_index: int = 0			# to use in idle_butto, to know which column
var is_hold: bool = true			# it's hold

## Variables for hold
var is_being_held:bool = false		# pressed?
var is_finished: bool = false		# finished?
var is_missed: bool = false 		# missed?

var judgment_y: float = 0.0										# judg.y

func _process(delta):

	position.y += speed * delta										# move
	
	## Holding logic
	if is_being_held:												# if it holding
		var overshoot = position.y - judgment_y						# how much head need to be comprase
		head.position.y = -overshoot								# pull head toward judg and shrink body
		
		var length_to_decrese = body.size.y - (speed * delta) 		# how much body need to be comprase
		
		if length_to_decrese <= 0:									# if it's end
			body.size.y = 0
			is_finished = true
		else:
			body.size.y = length_to_decrese
			body.position.y = head.position.y - body.size.y
			bottom.position.y = body.position.y
			
	else:															# it isn't pressed
		if not is_missed and global_position.y > judgment_y + 50:	# miss?
			mark_as_miss()

	var tail_global_y = global_position.y + bottom.position.y		# tail.y (head)
	
	if tail_global_y > judgment_y + 50:								# if misss
		queue_free()
	
	if is_finished:													# if success
		queue_free()

## setup position every part of hold note
## [length_px] - duration hold note in pixel
func setup_hold(length_px: float):
	body.size.y = length_px
	head.position.y = 0 
	body.position.y = -length_px
	bottom.position.y = -length_px

## check holding
func start_holding():
	if not is_missed:
		is_being_held = true

## makr miss
func mark_as_miss():
	is_missed = true
	Global.combo = "Miss"
	Global.combo_score = 0 
	## Miss Animation
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.3, 0.3, 0.3, 0.5), 0.3)
