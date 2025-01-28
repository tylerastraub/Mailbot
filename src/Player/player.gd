extends CharacterBody3D

class_name Player

const LERP_VALUE : float = 0.15
const ANIMATION_BLEND : float = 20.0

var snap_vector : Vector3 = Vector3.DOWN
var speed : float

var ticks_since_last_boost : float = 2.0;
var boost : bool = false
var boost_amount : float = 1.0

var throw_target : Node3D = null
var is_throwing : bool = false
var throw_timer : float = 0.0
var throw_sweetspot_start : float = 0.0
var throw_sweetspot_length : float = 0.0
var throw_sweetspot_upper_bounds : float = 0.5
var throw_sweetspot_max_length : float = 0.4
const THROW_TIME_LIMIT : float = 2.0
const THROW_SWEETSPOT_END_BUFFER : float = 0.1
const ERRANT_THROW_MAX_RANGE : float = 20.0

var package_child : Package = null
var envelope_child : Envelope = null

var raycast_result : Dictionary

var npc_targets : Array
var npc_targets_remove_queue : Array
var npc_lock_minimum : float = 1.0 # number of seconds for lock on status to appear
var npc_lock_maximum : float = 3.0 # number of seconds of locking on before killing

var is_on_stairs : bool = false

@export_group("Resources")
@export var player_mesh : Node3D
@export var spring_arm_pivot : Node3D
@export var animation_tree : AnimationTree
@export var camera : Camera3D
@export var ui : CanvasLayer
@export var envelope : PackedScene
@export var hand_attachment : BoneAttachment3D
@export var laser : Laser

@export_group("Movement variables")
@export var walk_speed : float = 4.0
@export var boost_speed : float = 8.0
@export var throwing_move_speed : float = 2.0
@export var package_carry_move_speed : float = 3.0
@export var jump_strength : float = 10.0
@export var gravity : float = 30.0

@export_group("Boost settings")
@export var jump_boost_threshold : float = 0.25 # Minimum boost required to start jumping.
@export var boost_drain : float = 0.005 # How fast boost drains charge.
@export var boost_recharge : float = 0.004 # How fast boost recharges.
@export var boost_timeout : float = 2.0 # Number of seconds boost won't charge if completely drained.

@export_group("Laser")
@export var laser_speed : float = 0.05 # num of seconds for laser to get max width
@export var laser_duration : float = 0.2 # how long laser lasts
@export var laser_fade : float = 0.1 # laser fade away duration
const LASER_BASE_WIDTH : float = 0.06
var laser_timer = 0.0

func _ready() -> void:
	$Mesh/ViewCone.connect("body_entered", _on_body_entered)
	$Mesh/ViewCone.connect("body_exited", _on_body_exited)
	laser.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_released("pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
	
	raycast_result = camera.make_raycast()

func _physics_process(delta):
	#throwing
	if Input.is_action_just_pressed("throw") and is_on_floor():
		if package_child != null:
			throw_package()
		elif is_throwing:
			throw_envelope()
		elif raycast_result.size() > 0:
			if raycast_result.collider is Mailbox:
				throw_target = raycast_result.collider
				start_envelope_throw()
	if is_throwing:
		if throw_timer >= THROW_TIME_LIMIT or not is_on_floor():
			throw_envelope()
	
	#laser stuff
	if Input.is_action_just_pressed("interact") and is_on_floor() and is_throwing == false and raycast_result.size() > 0:
		if raycast_result.collider is Package:
			pick_up_package(raycast_result.collider)

	for pair in npc_targets:
		if pair[1] > npc_lock_minimum - delta / 2 and pair[1] < npc_lock_minimum + delta / 2:
			print("LOCKING ON...")
		if pair[1] > npc_lock_maximum:
			shoot_laser(pair[0])
			npc_targets_remove_queue.push_back(pair[0])
	# remove npc after full iteration to avoid messing up iterator
	for npc in npc_targets_remove_queue:
		remove_npc_target(npc)
	npc_targets_remove_queue.clear()
	
	throw_timer += delta
	laser_timer += delta
	for pair in npc_targets:
		pair[1] += delta
	
	move_player(delta)
	apply_floor_snap()
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * 1.0)
	
	check_for_stairs()
	animate(delta)

func start_envelope_throw():
	is_throwing = true
	throw_timer = 0.0
	var ray_length = camera.RAY_LENGTH
	var throw_distance = global_position.distance_to(throw_target.global_position)
	throw_sweetspot_length = throw_sweetspot_upper_bounds - throw_sweetspot_max_length * (min(throw_distance / ray_length, 1.0))
	throw_sweetspot_start = randf_range(0.5, THROW_TIME_LIMIT - throw_sweetspot_length - THROW_SWEETSPOT_END_BUFFER)
	# spawn envelope in hand
	envelope_child = envelope.instantiate()
	hand_attachment.add_child(envelope_child)
	# hard coded yuck
	envelope_child.position = Vector3(-0.06, 0.12, 0.012)
	envelope_child.rotation_degrees = Vector3(2.9, 4.7, -61.5)
	SignalManager.playerStartThrow.emit(throw_sweetspot_start, throw_sweetspot_length, THROW_TIME_LIMIT)

func throw_envelope():
	is_throwing = false
	envelope_child.top_level = true
	envelope_child.rotation_degrees = Vector3(0, 90, -60.0)
	if throw_timer <= throw_sweetspot_start + throw_sweetspot_length and throw_timer >= throw_sweetspot_start:
		SignalManager.throwEnvelope.emit(envelope_child, self, throw_target, Vector3(0, 1.2, 0))
	else:
		throw_target = find_nearest_npc(ERRANT_THROW_MAX_RANGE)
		SignalManager.throwEnvelope.emit(envelope_child, self, throw_target, Vector3(0, 0.3, 0))
	# todo: if failed throw, change target to random NPC nearby
	SignalManager.playerStopThrow.emit()
	throw_target = null
	envelope_child.reparent(get_parent())
	envelope_child = null
	animation_tree.set("parameters/ThrowBlend/blend_amount", -1.0)

func move_player(delta: float):
	var move_direction : Vector3 = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y).normalized()
	
	velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("boost") and ticks_since_last_boost >= boost_timeout:
		boost = true
		SignalManager.playerStartBoost.emit(boost_amount, boost_drain)
	if boost_amount <= 0 or not Input.is_action_pressed("boost"):
		if boost_amount <= 0 and boost:
			ticks_since_last_boost = 0.0
			boost_timeout = 3.0
		elif boost:
			ticks_since_last_boost = 0.0
			boost_timeout = 1.0
		boost = false
		
	if boost and not is_throwing and package_child == null:
		speed = boost_speed
		boost_amount -= boost_drain
	else:
		if package_child != null:
			speed = package_carry_move_speed
		else:
			speed = throwing_move_speed if is_throwing else walk_speed
		if(ticks_since_last_boost >= boost_timeout):
			boost_amount += boost_recharge
		
	boost_amount = clamp(boost_amount, 0.0, 1.0)
	ticks_since_last_boost += delta
	
	#print("boost", boost_amount)
	
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	
	if is_throwing:
		var target_angle = global_position.direction_to(throw_target.global_position)
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-target_angle.x, -target_angle.z), 0.5)
	elif move_direction:
		player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, atan2(-velocity.x, -velocity.z), LERP_VALUE)
	
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump") and boost_amount >= jump_boost_threshold and not is_throwing
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
		boost_amount -= jump_boost_threshold
		ticks_since_last_boost = 0.0
		boost_timeout = 1.0 if boost_amount > 0.0 else 3.0
	elif just_landed:
		snap_vector = Vector3.DOWN

func animate(delta):
	if is_on_floor() or is_on_stairs:
		animation_tree.set("parameters/GroundAirBlend/blend_amount", lerpf(animation_tree.get("parameters/GroundAirBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		if is_throwing:
			animation_tree.set("parameters/IdleBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/RunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/JumpBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		elif package_child != null:
			animation_tree.set("parameters/IdleBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/RunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/JumpBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
		else:
			animation_tree.set("parameters/IdleBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), -1.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/RunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), -1.0, delta * ANIMATION_BLEND))
			animation_tree.set("parameters/JumpBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		if Vector3(velocity.x, 0.0, velocity.z).length() > 0:
			animation_tree.set("parameters/IdleRunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleRunBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
		else:
			animation_tree.set("parameters/IdleRunBlend/blend_amount", lerpf(animation_tree.get("parameters/IdleRunBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
	else:
		animation_tree.set("parameters/GroundAirBlend/blend_amount", lerpf(animation_tree.get("parameters/GroundAirBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
		if package_child != null:
			animation_tree.set("parameters/JumpBlend/blend_amount", lerpf(animation_tree.get("parameters/JumpBlend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
		else:
			animation_tree.set("parameters/JumpBlend/blend_amount", lerpf(animation_tree.get("parameters/JumpBlend/blend_amount"), 0.0, delta * ANIMATION_BLEND))

func find_nearest_npc(max_range: float) -> NPC:
	var npcs = get_tree().get_nodes_in_group("NPCs")
	if npcs.is_empty():
		return null
	var nearest : NPC = npcs.front()
	npcs.pop_front()
	
	for npc in npcs:
		if npc.is_alive == false:
			continue
		if global_position.distance_to(npc.global_position) < global_position.distance_to(nearest.global_position):
			nearest = npc
	
	if global_position.distance_to(nearest.global_position) <= max_range and nearest.is_alive:
		return nearest
	
	return null

func shoot_laser(target: NPC):
	if target == null:
		return
	laser.laser_timer = 0.0
	laser.target = target
	target.kill_npc(global_position.direction_to(target.global_position) * laser.laser_strength + Vector3(0.0, 20.0, 0.0))
	laser.burn_target()
	laser.show()

func add_npc_target(npc: NPC):
	if npc.is_alive and npc_targets.has(npc) == false:
		npc_targets.push_back([npc, 0.0])
		print("added NPC to list")

func remove_npc_target(npc: NPC):
	for pair in npc_targets:
		if pair.has(npc):
			npc_targets.erase(pair)
			print("removed NPC from list")

func check_for_stairs():
	is_on_stairs = false
	if velocity.y > 0:
		return
	if $Mesh/LedgeCheck/LedgeCheckLowerLeft.is_colliding() and $Mesh/LedgeCheck/LedgeCheckUpperLeft.is_colliding() == false and $Mesh/LedgeCheck/LedgeHeightCheckLeft.is_colliding():
		if $Mesh/LedgeCheck/LedgeHeightCheckLeft.get_collision_normal() == Vector3.UP:
			global_position.y = $Mesh/LedgeCheck/LedgeHeightCheckLeft.get_collision_point().y
			velocity.y = 0
			is_on_stairs = true
	elif $Mesh/LedgeCheck/LedgeCheckLowerRight.is_colliding() and $Mesh/LedgeCheck/LedgeCheckUpperRight.is_colliding() == false and $Mesh/LedgeCheck/LedgeHeightCheckRight.is_colliding():
		if $Mesh/LedgeCheck/LedgeHeightCheckRight.get_collision_normal() == Vector3.UP:
			global_position.y = $Mesh/LedgeCheck/LedgeHeightCheckRight.get_collision_point().y
			velocity.y = 0
			is_on_stairs = true

func pick_up_package(package: Package):
	package.get_parent().reparent(hand_attachment, false)
	package.pick_up()
	package.get_parent().position = Vector3(-0.225, 0.153, -0.045)
	package.get_parent().rotation_degrees = Vector3(6.3, 87.4, -17.0)
	package_child = package

func throw_package():
	package_child.get_parent().reparent(self)
	package_child.get_thrown()
	package_child = null

func _on_body_entered(body: Node3D):
	if body is NPC:
		add_npc_target(body)

func _on_body_exited(body: Node3D):
	if body is NPC:
		remove_npc_target(body)
