extends Node3D

class_name Mailbox

@export var outline_width : float = 2.0

var open : bool = true

func _ready() -> void:
	SignalManager.mailboxHoverOn.connect(_on_ray_entered)
	SignalManager.mailboxHoverOff.connect(_on_ray_exited)
	SignalManager.envelopeDelivered.connect(_on_envelope_delivered)
	$Mesh/Cube.get("material_overlay").set("shader_parameter/outline_width", outline_width)
	$Mesh/Cube.get("material_overlay").set("shader_parameter/enabled", false)
	
func _on_ray_entered(mailbox: Mailbox):
	if mailbox == self and open:
		$Mesh/Cube.get("material_overlay").set("shader_parameter/enabled", true)
	
func _on_ray_exited(mailbox: Mailbox):
	if mailbox != self:
		$Mesh/Cube.get("material_overlay").set("shader_parameter/enabled", false)

func _on_envelope_delivered(_deliverer: Node3D, _envelope: Envelope, recipient: Node3D):
	if recipient == self:
		$Mesh/AnimationPlayer.current_animation = "Close"
		$Mesh/AnimationPlayer.speed_scale = 2.0
		open = false
		SignalManager.mailboxClosed.emit()
