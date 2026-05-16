extends Node

## Plays pop animation for label
## [label] - Label to animate
func pop_label(label: Label) -> void:

	var t: Tween = label.create_tween()
	label.set_meta("pop_tween", t)

	# Soft pop up
	t.tween_property(label, "scale", Vector2(1.04, 1.04), 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "scale", Vector2(1.02, 1.02), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
