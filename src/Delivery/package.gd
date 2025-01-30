extends Area3D

class_name Package

@export var collision : CollisionShape3D = null
@export var mesh : MeshInstance3D = null
@export var rigidbody : RigidBody3D = null

@export var outline_width : float = 2.0

var destination : NPCTargetArea = null

func _ready() -> void:
	SignalManager.packageHoverOn.connect(_on_ray_entered)
	SignalManager.packageHoverOff.connect(_on_ray_exited)
	SignalManager.packageDelivered.connect(_on_package_delivered)
	body_entered.connect(_on_body_entered)
	if ProjectSettings.get_setting("render/compatibility_mode") == false:
		mesh.get("material_overlay").set("shader_parameter/outline_width", outline_width)
		mesh.get("material_overlay").set("shader_parameter/enabled", false)
	else:
		mesh.set("material_overlay", null)

func pick_up():
	get_parent().top_level = false
	$AreaCollision.disabled = true
	collision.disabled = true
	rigidbody.freeze = true
	SignalManager.packagePickedUp.emit(self)
	if ProjectSettings.get_setting("render/compatibility_mode") == false:
		mesh.get("material_overlay").set("shader_parameter/enabled", false)
	
func get_thrown():
	get_parent().top_level = true
	$AreaCollision.disabled = false
	collision.disabled = false
	rigidbody.freeze = false
	rigidbody.apply_central_force(Vector3(500.0, 70.0, 0.0).rotated(Vector3.UP, rigidbody.global_rotation.y))
	if ProjectSettings.get_setting("render/compatibility_mode") == false:
		mesh.get("material_overlay").set("shader_parameter/enabled", true)

func _on_ray_entered(package: Package):
	if package == self:
		if ProjectSettings.get_setting("render/compatibility_mode") == false:
			mesh.get("material_overlay").set("shader_parameter/enabled", true)
	
func _on_ray_exited(package: Package):
	if package != self:
		if ProjectSettings.get_setting("render/compatibility_mode") == false:
			mesh.get("material_overlay").set("shader_parameter/enabled", false)

func _on_body_entered(body: Node):
	if body is NPC:
		if body.is_alive:
			body.kill_npc(Vector3.ZERO)

func _on_package_delivered(package: Package):
	if package == self:
		get_parent().call_deferred("queue_free")
