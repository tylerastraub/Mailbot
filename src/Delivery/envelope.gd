extends Node3D

class_name Envelope

const THROW_TIMER_LIMIT = 5.0

var rotation_speed : float = 0.5
var move_speed : float = 10.0
var thrown_by : Node3D = null
var target : Node3D = null
var target_offset : Vector3 = Vector3.ZERO
var thrown : bool = false
var throw_timer : float = 0.0
var errant_throw_direction : Vector3 = Vector3.ZERO

var velocity : Vector3 = Vector3.ZERO

func _ready() -> void:
	SignalManager.connect("throwEnvelope", _on_throw_envelope)
	$Area3D.connect("area_entered", _on_area_entered)
	$Area3D.connect("body_entered", _on_body_entered)
	
func _physics_process(delta: float) -> void:
	if thrown:
		$Mesh.rotate_y(rotation_speed)
		if target != null:
			var new_pos = global_position.move_toward(target.global_position + target_offset, move_speed * delta)
			velocity = (new_pos - global_position) / delta
			global_position = new_pos
		else:
			var new_pos = global_position + errant_throw_direction.normalized() * move_speed * delta
			velocity = (new_pos - global_position) / delta
			global_position = new_pos
		throw_timer += delta
		if throw_timer >= THROW_TIMER_LIMIT:
			queue_free()
	
func _on_throw_envelope(envelope: Node3D, thrower: Node3D, throw_target: Node3D, throw_target_offset: Vector3):
	if throw_target == null:
		thrown = true
		thrown_by = owner
		global_position.y = thrower.global_position.y + 1.5
		errant_throw_direction = Vector3(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		
	if envelope == self:
		thrown = true
		thrown_by = thrower
		target = throw_target
		if target is Mailbox:
			target.open = false
			SignalManager.mailboxHoverOff.emit(null)
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
