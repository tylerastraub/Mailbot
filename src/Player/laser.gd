extends RayCast3D

class_name Laser

@onready var beam_mesh = $Mesh

var target : Node3D = null

@export var burn_material : StandardMaterial3D

@export_category("Laser Settings")
@export var laser_speed : float = 0.02 # num of seconds for laser to get max width
@export var laser_duration : float = 0.2 # how long laser lasts
@export var laser_fade : float = 0.18 # laser fade away duration
@export var laser_strength : float = 40.0 # how hard laser hits target
const LASER_BASE_WIDTH : float = 0.06
var laser_timer : float = 0.0

const MAX_ALPHA = 214

func _physics_process(delta: float) -> void:
	if laser_timer <= laser_duration and target != null:
		var laser_distance = global_position.distance_to(target.global_position)
		look_at(target.global_position + Vector3(0.0, 0.75, 0.0))
		rotation_degrees.x += 90
		# laser width
		var laser_power = min(laser_timer / laser_speed, 1.0)
		beam_mesh.mesh.top_radius = LASER_BASE_WIDTH * laser_power
		beam_mesh.mesh.bottom_radius = LASER_BASE_WIDTH * laser_power
		beam_mesh.mesh.height = laser_distance
		beam_mesh.position.y = laser_distance / -2
		target_position.y = laser_distance * -1 - 1.0
		# laser alpha
		var albedo : Color = beam_mesh.mesh.material.albedo_color
		var start_alpha : float = MAX_ALPHA / 255.0
		albedo.a = (start_alpha * (min((laser_fade - laser_timer) / laser_fade + laser_duration - laser_fade, 1.0)))
		beam_mesh.mesh.material.albedo_color = albedo
	elif visible:
		target = null
		hide()
	if visible:
		var cast_point
		force_raycast_update()
		if is_colliding():
			cast_point = to_local(get_collision_point())
			
			beam_mesh.mesh.height = cast_point.y
			beam_mesh.position.y = cast_point.y / 2
	laser_timer += delta

func burn_target():
	if target != null:
		var meshes = target.find_children("*", "MeshInstance3D")
		if meshes.size() > 0:
			for mesh in meshes:
				mesh.set_surface_override_material(0, burn_material)
