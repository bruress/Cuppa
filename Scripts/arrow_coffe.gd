extends Area2D

var speed: float = 0.0				# changed in rhythm game
var column_index: int = 0			# to use in idle_butto, to know which column
var is_hold: bool = false			# isn't hold

func _process(delta):
	position.y += speed * delta		# move
	if global_position.y >= 450:	# exited behind screen
		queue_free()				# clear
