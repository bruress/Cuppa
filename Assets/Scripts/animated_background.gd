extends Sprite2D

@export_dir var frames_directory: String
@export var frames_count: int = 64
@export var frames_per_second: float = 20.0

var frames: Array[Texture2D] = []
var elapsed_time: float = 0.0
var current_frame: int = 0


func _ready() -> void:
	for frame_index in range(frames_count):
		var frame_path := "%s/frame_%02d.png" % [frames_directory, frame_index]
		var frame_texture := load(frame_path) as Texture2D
		if frame_texture != null:
			frames.append(frame_texture)

	if not frames.is_empty():
		texture = frames[0]


func _process(delta: float) -> void:
	if frames.size() < 2:
		return

	elapsed_time += delta
	var frame_duration := 1.0 / frames_per_second

	while elapsed_time >= frame_duration:
		elapsed_time -= frame_duration
		current_frame = (current_frame + 1) % frames.size()
		texture = frames[current_frame]
