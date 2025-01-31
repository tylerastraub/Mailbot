extends CanvasLayer

class_name GameOverScreen

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("interact"):
		SignalManager.restartLevel.emit()
