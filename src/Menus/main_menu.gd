extends Node3D

func _ready() -> void:
	$mailbot/AnimationPlayer.current_animation = "ProudStance"
	$AudioStreamPlayer.play()

func _on_play_button_pressed() -> void:
	SignalManager.playGame.emit()

func _on_quit_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
