extends RefCounted

const BASE_PULSE_SPEED: float = 4.4
const BASE_PULSE_AMOUNT: float = 0.18
const SECOND_PULSE_SPEED: float = 8.2
const SECOND_PULSE_AMOUNT: float = 0.08
const COMBO_BOOST_ALPHA: float = 0.40
const SMOOTH_SPEED: float = 10.0

## Updates both side lights every frame
## [left_light] - Left light sprite
## [right_light] - Right light sprite
## [left_base_alpha] - Base alpha for left light
## [right_base_alpha] - Base alpha for right light
## [song_time] - Current game time
## [combo_score] - Current combo score
func update_lights(left_light: Sprite2D, right_light: Sprite2D, left_base_alpha: float, right_base_alpha: float, song_time: float, combo_score: int, delta: float) -> void:
	
	var pulse_1: float = sin(song_time * BASE_PULSE_SPEED) * BASE_PULSE_AMOUNT
	var pulse_2: float = sin(song_time * SECOND_PULSE_SPEED) * SECOND_PULSE_AMOUNT
	var pulse: float = pulse_1 + pulse_2

	# Add brightness on high combo
	var boost: float = 0.0
	if (combo_score >= 30):
		boost = COMBO_BOOST_ALPHA

	var left_target: float = clamp(left_base_alpha + pulse + boost, 0.0, 1.0)
	var right_target: float = clamp(right_base_alpha - pulse + boost, 0.0, 1.0)
	var t: float = min(delta * SMOOTH_SPEED, 1.0)		# Smooth coef

	# Move both lights smoothly
	left_light.modulate.a = lerp(left_light.modulate.a, left_target, t)
	right_light.modulate.a = lerp(right_light.modulate.a, right_target, t)
