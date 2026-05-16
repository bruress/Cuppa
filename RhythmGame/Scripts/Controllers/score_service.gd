extends RefCounted

const PERFECT_WINDOW_PX: float = 50.0
const GOOD_WINDOW_PX: float = 80.0
const LAME_WINDOW_PX: float = 110.0

const PERFECT_SCORE: int = 10
const GOOD_SCORE: int = 5
const LAME_SCORE: int = 1
const COMBO_STEP: int = 10

const PERFECT_COLOR := Color(1.0, 0.0, 0.318, 1.0)
const GOOD_COLOR := Color(1.0, 0.664, 0.531, 1.0)
const LAME_COLOR := Color(0.336, 0.782, 0.878, 1.0)
const MISS_COLOR := Color(0.125, 0.072, 0.146, 1.0)

static func evaluate_distance(distance: float) -> Dictionary:
	if distance < PERFECT_WINDOW_PX:
		return {
			"combo_text": "Bloody bite",
			"score_delta": PERFECT_SCORE,
			"combo_delta": COMBO_STEP,
			"reset_combo": false,
			"hit_color": PERFECT_COLOR,
		}
	if distance < GOOD_WINDOW_PX:
		return {
			"combo_text": "Bloody",
			"score_delta": GOOD_SCORE,
			"combo_delta": COMBO_STEP,
			"reset_combo": false,
			"hit_color": GOOD_COLOR,
		}
	if distance < LAME_WINDOW_PX:
		return {
			"combo_text": "Lame",
			"score_delta": LAME_SCORE,
			"combo_delta": COMBO_STEP,
			"reset_combo": false,
			"hit_color": LAME_COLOR,
		}

	return {
		"combo_text": "Miss",
		"score_delta": 0,
		"combo_delta": 0,
		"reset_combo": true,
		"hit_color": MISS_COLOR,
	}

static func evaluate_hold_progress(progress: float) -> Dictionary:
	if progress >= 0.85:
		return {
			"combo_text": "Bloody bite",
			"score_delta": PERFECT_SCORE,
			"combo_delta": COMBO_STEP,
			"hit_color": PERFECT_COLOR,
		}
	if progress >= 0.50:
		return {
			"combo_text": "Bloody",
			"score_delta": GOOD_SCORE,
			"combo_delta": COMBO_STEP,
			"hit_color": GOOD_COLOR,
		}
	return {
		"combo_text": "Lame",
		"score_delta": LAME_SCORE,
		"combo_delta": COMBO_STEP,
		"hit_color": LAME_COLOR,
	}
