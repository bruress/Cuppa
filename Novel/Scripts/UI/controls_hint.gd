extends CanvasLayer

signal confirmed

@onready var ok_button: Button = $Panel/OkButton
var is_confirmed: bool = false

## Bind controls hint actions
func _ready() -> void:
	ok_button.pressed.connect(confirm_hint)

## Emit signal once and close
func confirm_hint() -> void:
	if (is_confirmed):
		return
	is_confirmed = true
	confirmed.emit()
	queue_free()
