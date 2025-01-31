extends Control

var num_kills : int = 0

const ICON_WIDTH : int = 75

func _ready() -> void:
	SignalManager.connect("npcKilled", _on_npc_killed)
	SignalManager.connect("packageDelivered", _on_package_delivered)

func set_kills(kills: int):
	num_kills = kills
	$Icon.size.x = num_kills * ICON_WIDTH
	$Icon.visible = true if kills > 0 else false

func _on_npc_killed():
	set_kills(num_kills - 1)
	if num_kills == 0:
		SignalManager.gameOver.emit()

func _on_package_delivered(_package: Package):
	set_kills(num_kills + 1)
