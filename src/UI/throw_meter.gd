extends Control

var timer : float = 0.0
var timer_length : float = 0.0

func _ready() -> void:
	SignalManager.playerStartThrow.connect(_on_start_throw)
	SignalManager.playerStopThrow.connect(_on_stop_throw)
	hide()
	
func _physics_process(delta: float) -> void:
	timer += delta
	if visible:
		var meter_range = $Meter.size.y - $Marker.size.y
		$Marker.position.y = $Meter.position.y + meter_range - (timer / timer_length * meter_range)
	
func _on_start_throw(sweetspotStart: float, sweetspotLength: float, timerLength: float):
	timer_length = timerLength
	timer = 0.0
	$Sweetspot.size.y = sweetspotLength / timerLength * $Meter.size.y
	$Sweetspot.position.y = $Meter.position.y + $Meter.size.y - sweetspotStart / timerLength * $Meter.size.y - $Sweetspot.size.y
	$Marker.position.y = $Meter.position.y + $Meter.size.y - $Marker.size.y
	show()
	
func _on_stop_throw():
	hide()
