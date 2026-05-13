extends Area2D

# Remove note after this Y to keep scene clean
const DESPAWN_Y = 450.0

# Set by rhythm_game to control note fall speed
var speed: float = 0.0

# Match note with input lane
var column_index: int = 0

# Tap note marker for shared hit logic
var is_hold: bool = false

# Move note and clear it outside play area
func _process(delta: float) -> void:
	position.y += speed * delta	# Move
	if global_position.y >= DESPAWN_Y:	# Exited behind screen
		queue_free()	# Clear
