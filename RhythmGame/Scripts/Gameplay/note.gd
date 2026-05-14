extends Area2D

# Delete note after this Y
const DESPAWN_Y = 450.0

# Speed note
var speed: float = 0.0

# Column
var lane_index: int = 0

# Is this obviously a note or hold
var is_hold: bool = false

func _process(delta: float) -> void:
	position.y += speed * delta			# Move
	if global_position.y >= DESPAWN_Y:
		queue_free()					# Delete
