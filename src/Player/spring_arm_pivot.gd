extends Node3D

@export var normal_fov : float = 70
@export var boost_fov : float = 90

@export var default_spring_length = 3.5
@export var zoom_spring_length = 1.5

@export var mouse_sensitivity : float = 0.25
@export var joy_sensitivity : float = 0.25

@export var spring_arm : SpringArm3D
@export var camera : Camera3D

const CAMERA_BLEND : float = 0.05
const DEADZONE = 0.1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and not owner.is_throwing:
		rotate_y(-event.relative.x * 0.005 * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * 0.005 * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -5 * PI / 12, PI/3)
	elif event is InputEventJoypadMotion and event.get_axis_value() > DEADZONE:
		pass

func _physics_process(_delta):
	if owner.is_on_floor():
		if owner.is_throwing:
			spring_arm.spring_length = lerpf(spring_arm.spring_length, zoom_spring_length, CAMERA_BLEND * 5)
		else:
			spring_arm.spring_length = lerpf(spring_arm.spring_length, default_spring_length, CAMERA_BLEND * 5)
			if owner.boost and owner.package_child == null:
				camera.fov = lerp(camera.fov, boost_fov, CAMERA_BLEND)
			else:
				camera.fov = lerp(camera.fov, normal_fov, CAMERA_BLEND)
	else:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, default_spring_length, CAMERA_BLEND * 5)
		camera.fov = lerp(camera.fov, normal_fov, CAMERA_BLEND)
	
	if owner.is_throwing and owner.throw_target != null:
		pass
		# todo: https://www.youtube.com/watch?v=lbUdYEdraDs
		#var dir = spring_arm.global_position.direction_to(owner.throw_target.global_position)
		#rotation.y = -dir.y
		#spring_arm.rotation.x = -dir.x
