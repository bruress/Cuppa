extends RefCounted

const BASE_PULSE_SPEED: float = 4.4
const BASE_PULSE_AMOUNT: float = 0.18
const SECOND_PULSE_SPEED: float = 8.2
const SECOND_PULSE_AMOUNT: float = 0.08
const SMOOTH_SPEED: float = 10.0

## Updates any amount of menu lights
## [lights] - Array of light sprites
## [base_alphas] - Base alpha for each light
## [delta] - Frame delta
## [time_sec] - Current time in seconds
func update_lights(
	lights: Array[Sprite2D],
	base_alphas: Array[float],
	delta: float,
	time_sec: float
) -> void:
	if lights.is_empty():
		return
	if lights.size() != base_alphas.size():
		return

	var pulse_1: float = sin(time_sec * BASE_PULSE_SPEED) * BASE_PULSE_AMOUNT
	var pulse_2: float = sin(time_sec * SECOND_PULSE_SPEED) * SECOND_PULSE_AMOUNT
	var pulse: float = pulse_1 + pulse_2
	var t: float = min(delta * SMOOTH_SPEED, 1.0)

	for i in range(lights.size()):
		var light: Sprite2D = lights[i]
		if not is_instance_valid(light):
			continue
		var base_alpha: float = base_alphas[i]
		var pulse_direction: float = 1.0 if i % 2 == 0 else -1.0
		var target_alpha: float = clamp(base_alpha + (pulse * pulse_direction), 0.0, 1.0)
		light.modulate.a = lerp(light.modulate.a, target_alpha, t)
