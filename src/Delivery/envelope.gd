extends Node3D

class_name Envelope

var rotation_speed : float = 0.5
var move_speed : float = 10.0
var thrown_by : Node3D = null
var target : Node3D = null
var target_offset : Vector3 = Vector3.ZERO
var thrown : bool = false

var velocity : Vector3 = Vector3.ZERO

func _ready() -> void:
	SignalManager.connect("throwEnvelope", _on_throw_envelope)
	$Area3D.connect("area_entered", _on_area_entered)
	$Area3D.connect("body_entered", _on_body_entered)
	
func _physics_process(delta: float) -> void:
	if thrown and target != null:
		$Mesh.rotate_y(rotation_speed)
		var new_pos = global_position.move_toward(target.global_position + target_offset, move_speed * delta)
		velocity = (new_pos - global_position) / delta
		global_position = new_pos
	
func _on_throw_envelope(envelope: Node3D, thrower: Node3D, throw_target: Node3D, throw_target_offset: Vector3):
	if throw_target == null:
		queue_free()
	if envelope == self:
		thrown = true
		thrown_by = thrower
		target = throw_target
		target_offset = throw_target_offset
		global_position.y = thrower.global_position.y + 1.5

func _on_area_entered(area: Node3D) -> void:
	if area == target:
		SignalManager.envelopeDelivered.emit(thrown_by, self, target)
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body == target:
		SignalManager.envelopeDelivered.emit(thrown_by, self, target)
		queue_free()
