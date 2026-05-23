extends Node

var score: int = 0
var combo_score: int = 0

# Combo text
var combo: String = ""

# Hold note length
var lenght_long: float = 0.0

# Judged notes for accuracy percent
var judged_count: int = 0

# Current novel client key: mary/boy/hunter
var current_client: String = "mary"

# Novel flow state: mary_intro -> mary_result
var novel_state: String = "mary_intro"

# Last finished rhythm accuracy in percent
var last_accuracy: float = 0.0

# Bad rhythm results for ending logic
var bad_results_count: int = 0

# Show controls hint only once before first rhythm start
var rhythm_controls_seen: bool = false

# Runtime-only continue from menu (no file save)
var can_resume: bool = false
var resume_scene_path: String = ""
