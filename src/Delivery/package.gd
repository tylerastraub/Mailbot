extends Area3D

class_name Package

@export var collision : CollisionShape3D = null
@export var mesh : MeshInstance3D = null
@export var rigidbody : RigidBody3D = null

@export var outline_width : float = 2.0

func _ready() -> void:
	SignalManager.packageHoverOn.connect(_on_ray_entered)
	SignalManager.packageHoverOff.connect(_on_ray_exited)
	body_entered.connect(_on_body_entered)
	mesh.get("material_overlay").set("shader_parameter/outline_width", outline_width)
	mesh.get("material_overlay").set("shader_parameter/enabled", false)

func pick_up():
	get_parent().top_level = false
	$AreaCollision.disabled = true
	collision.disabled = true
	rigidbody.freeze = true
	
func get_thrown():
	get_parent().top_level = true
	$AreaCollision.disabled = false
	collision.disabled = false
	rigidbody.freeze = false
	rigidbody.apply_central_force(Vector3(500.0, 70.0, 0.0).rotated(Vector3.UP, rigidbody.global_rotation.y))

func _on_ray_entered(package: Package):
	if package == self:
		mesh.get("material_overlay").set("shader_parameter/enabled", true)
	
func _on_ray_exited(package: Package):
	if package != self:
		mesh.get("material_overlay").set("shader_parameter/enabled", false)

func _on_body_entered(body: Node):
	if body is NPC:
		if body.is_alive:
			body.kill_npc(Vector3.ZERO)
