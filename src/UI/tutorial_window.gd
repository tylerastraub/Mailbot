extends CanvasLayer

class_name TutorialWindow

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("interact"):
		self.visible = false
		SignalManager.tutorialClosed.emit()

func set_text(text: String):
	$ColorRect/Text.text = text
