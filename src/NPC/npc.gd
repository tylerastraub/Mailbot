extends CharacterBody3D

class_name NPC

const LERP_VALUE : float = 0.15
const ANIMATION_BLEND : float = 20.0

@export var nav : NavigationAgent3D = null
@export var bone_simulator : PhysicalBoneSimulator3D = null

@export var speed = 2.0
@export var acceleration = 10.0
@export var friction = 2.0
@export var gravity = 18.0

var is_alive : bool = true

# todo: create random movement, add death code (add ragdoll physics
# and blood particles once NPC models are done

func _ready() -> void:
	nav = $NavigationAgent3D
	set_nav_target(Vector3(20, 0, -41))
	
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

func set_nav_target(nav_target: Vector3):
	nav.target_position = nav_target

func _on_envelope_delivered(_deliverer: Node3D, envelope: Envelope, recipient: Node3D):
	if recipient == self:
		call_deferred("kill_npc", envelope.velocity * 4.0 + Vector3(0.0, 40.0, 0.0))
		print("OW!!!!!!!!!!!! im dead")

func kill_npc(force: Vector3):
	is_alive = false
	$AnimationTree.active = false
	$CollisionShape3D.disabled = true
	#for bone in $Mesh/Armature/Skeleton3D.get_parentless_bones():
		#$Mesh/Armature/Skeleton3D.set_bone_enabled(bone, false)
	bone_simulator.active = true
	bone_simulator.physical_bones_start_simulation()
	bone_simulator.find_child("Physical Bone Pelvis").apply_central_impulse(force)
	velocity = force
	
