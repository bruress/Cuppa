extends Area2D

# Delete note after this Y
const DESPAWN_Y = 450.0

var speed: float = 0.0
var line_index: int = 0

# Is this obviously a note or hold
var is_hold: bool = false

func _process(delta: float) -> void:
	# Move
	position.y += speed * delta
	if global_position.y >= DESPAWN_Y:
		queue_free()
