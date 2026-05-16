extends Node2D

@export var shape_texture: Texture2D
@export var shapes_count: int = 35
@export var min_scale: float = 0.75
@export var max_scale: float = 1.85
@export var min_speed_y: float = 18.0
@export var max_speed_y: float = 58.0
@export var drift_x: float = 14.0
@export var pulse_strength: float = 0.22
@export var pulse_speed: float = 2.2

# Rendered all sprites
var sprites: Array[Sprite2D] = []
# Speed (x/y random flight)
var speed: Array[Vector2] = []
# Random for alpha pulse
var pulse_offsets: Array[float] = []
# Base alpha for each particle
var base_alphas: Array[float] = []

## Builds floating clones once
func _ready() -> void:
	randomize()
	# Work in screen-centered coordinates
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_w: float = viewport_size.x * 0.5
	var half_h: float = viewport_size.y * 0.5
	
	var texture := shape_texture

	# Create particles with random size/position/speed/alpha
	for i in range(shapes_count):
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		var s := randf_range(min_scale, max_scale)
		sprite.scale = Vector2(s, s)
		sprite.position = Vector2(randf_range(-half_w, half_w), randf_range(-half_h, half_h))
		var a := randf_range(0.40, 0.72)
		sprite.modulate = Color(1.0, 1.0, 1.0, a)
		add_child(sprite)
		sprites.append(sprite)
		base_alphas.append(a)

		# Fly in all directions
		var vx: float = randf_range(-drift_x, drift_x)
		var vy_abs: float = randf_range(min_speed_y, max_speed_y)
		var vy: float = vy_abs if randf() < 0.5 else -vy_abs
		speed.append(Vector2(vx, vy))
		pulse_offsets.append(randf_range(0.0, TAU))

## Moves, pulses and clones each frame
func _process(delta: float) -> void:
	# Re-read viewport in case of resize
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_w: float = viewport_size.x * 0.5
	var half_h: float = viewport_size.y * 0.5

	# Extra border outside screen
	var wrap_margin: float = 60.0

	for i in range(sprites.size()):
		var sprite := sprites[i]
		# Move
		sprite.position += speed[i] * delta

		# Vertical wrap
		if sprite.position.y > half_h + wrap_margin:
			sprite.position.y = -half_h - wrap_margin
			sprite.position.x = randf_range(-half_w, half_w)
		elif sprite.position.y < -half_h - wrap_margin:
			sprite.position.y = half_h + wrap_margin
			sprite.position.x = randf_range(-half_w, half_w)

		# Wrap horizontally
		if sprite.position.x < -half_w - wrap_margin:
			sprite.position.x = half_w + wrap_margin
		elif sprite.position.x > half_w + wrap_margin:
			sprite.position.x = -half_w - wrap_margin

		# Alpha sin pulse
		var pulse: float = sin((Time.get_ticks_msec() / 1000.0) * pulse_speed + pulse_offsets[i]) * pulse_strength
		var target_alpha: float = clamp(base_alphas[i] + pulse, 0.20, 1.0)
		sprite.modulate.a = target_alpha
