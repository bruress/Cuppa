extends Area2D

# delete note after this Y
const DESPAWN_Y = 450.0

# speed note
var speed: float = 0.0

# column
var lane_index: int = 0

# is this obviously a note or hold?
var is_hold: bool = false

func _process(delta: float) -> void:
	position.y += speed * delta			# move
	if global_position.y >= DESPAWN_Y:
		queue_free()					# delete
