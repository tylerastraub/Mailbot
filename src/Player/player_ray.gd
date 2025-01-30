extends Camera3D

@export var spring_arm : SpringArm3D
@export var pivot : Node3D

var selected : Node3D = null

const RAY_LENGTH = 14
const MAX_PACKAGE_DISTANCE = 7.5

func _ready() -> void:
	pass
	
func _input(_event: InputEvent) -> void:
	var result = make_raycast()
	if result.is_empty():
		selected = null
		SignalManager.emit_signal("mailboxHoverOff", null)
		SignalManager.emit_signal("packageHoverOff", null)
	elif result.collider != selected:
		if result.collider is Mailbox:
			SignalManager.emit_signal("packageHoverOff", null)
			if result.collider.open:
				selected = result.collider
				SignalManager.emit_signal("mailboxHoverOn", result.collider)
		elif result.collider is Package and global_position.distance_to(result.collider.global_position) < MAX_PACKAGE_DISTANCE:
			selected = result.collider
			SignalManager.emit_signal("mailboxHoverOff", null)
			SignalManager.emit_signal("packageHoverOn", result.collider)

func make_raycast() -> Dictionary:
	var center : Vector2 = Vector2(576, 324)
	#var from = project_ray_origin(get_viewport().size / 2)
	#var to = from + project_ray_normal(get_viewport().size / 2) * RAY_LENGTH
	var from = project_ray_origin(center)
	var to = from + project_ray_normal(center) * RAY_LENGTH
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = false
	ray_query.collision_mask = 2
	return space.intersect_ray(ray_query)
