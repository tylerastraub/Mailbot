extends CharacterBody3D

class_name NPC

const LERP_VALUE : float = 0.15
const ANIMATION_BLEND : float = 20.0

@export var nav : NavigationAgent3D = null
@export var bone_simulator : PhysicalBoneSimulator3D = null
@export var animation_tree : AnimationTree = null

@export var speed = 1.0
@export var acceleration = 10.0
@export var friction = 2.0
@export var gravity = 18.0

var is_alive : bool = true
var nav_target : NPCTargetArea = null

func _ready() -> void:
	nav = $NavigationAgent3D
	SignalManager.connect("envelopeDelivered", _on_envelope_delivered)
	# wait for nav agent to sync map
	set_physics_process(false)
	call_deferred("await_nav_setup")
	
func await_nav_setup():
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if is_alive == false:
		return
	
	var move_direction : Vector3 = Vector3.ZERO
	move_direction = (nav.get_next_path_position() - global_position).normalized()
	
	var move_change : float = 0.0
	if is_on_floor():
		move_change = acceleration if move_direction else friction
	velocity.x = lerpf(velocity.x, move_direction.x * speed, move_change * delta)
	velocity.z = lerpf(velocity.z, move_direction.z * speed, move_change * delta)
	
	velocity.y -= gravity * delta
	
	$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VALUE)
	
	apply_floor_snap()
	move_and_slide()
	$Mesh/LedgeCheck.check_for_stairs(self)
	animate(delta)

func set_nav_target(target: NPCTargetArea):
	nav_target = target
	if nav_target == null: return
	nav.target_position = nav_target.global_position

func _on_envelope_delivered(_deliverer: Node3D, envelope: Envelope, recipient: Node3D):
	if recipient == self:
		call_deferred("kill_npc", envelope.velocity * 4.0 + Vector3(0.0, 40.0, 0.0))

func kill_npc(force: Vector3):
	is_alive = false
	$AnimationTree.active = false
	$CollisionShape3D.disabled = true
	$Mesh/LedgeCheck.queue_free()
	if ProjectSettings.get_setting("render/compatibility_mode") == false:
		bone_simulator.active = true
		bone_simulator.physical_bones_start_simulation()
		bone_simulator.find_child("Physical Bone Pelvis").apply_central_impulse(force)
		collision_layer = 16
		velocity = force
	else:
		visible = false
	
func animate(delta: float):
	var blend_target: float = 1.0 if Vector3(velocity.x, 0.0, velocity.z).length() > 0 else 0.0
	animation_tree.set("parameters/IdleRunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleRunBlend/blend_amount"), blend_target, delta * ANIMATION_BLEND))
