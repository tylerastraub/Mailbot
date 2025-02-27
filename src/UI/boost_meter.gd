extends Control

const THRESHOLD_AMOUNT : float = 0.25
const FADE_IN_SPEED : float = 0.2
const FADE_OUT_SPEED : float = 0.05

var player : Player

func _ready() -> void:
	modulate.a = 0.0
	$Meter/Threshold.position.x = $Meter.size.x * THRESHOLD_AMOUNT
	SignalManager.playerSpawned.connect(_on_player_spawned)

func _physics_process(_delta: float) -> void:
	$Meter/Marker.position.x = player.boost_amount * $Meter.size.x
	if player.boost_amount >= 1.0:
		modulate.a -= FADE_OUT_SPEED
	else:
		modulate.a += FADE_IN_SPEED
	modulate.a = clamp(modulate.a, 0.0, 1.0)
	modulate.g = player.boost_amount * 4.0
	modulate.b = player.boost_amount * 4.0

func _on_player_spawned(player_node: Player):
	player = player_node
