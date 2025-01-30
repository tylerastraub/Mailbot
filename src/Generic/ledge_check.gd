extends Node3D

func check_for_stairs(body: CharacterBody3D) -> bool:
	var is_on_stairs : bool = false
	if body.velocity.y > 0:
		return false
	if $LedgeCheckLowerLeft.is_colliding() and $LedgeCheckUpperLeft.is_colliding() == false and $LedgeHeightCheckLeft.is_colliding():
		if $LedgeHeightCheckLeft.get_collision_normal() == Vector3.UP:
			body.global_position.y = $LedgeHeightCheckLeft.get_collision_point().y
			body.velocity.y = 0
			is_on_stairs = true
	elif $LedgeCheckLowerRight.is_colliding() and $LedgeCheckUpperRight.is_colliding() == false and $LedgeHeightCheckRight.is_colliding():
		if $LedgeHeightCheckRight.get_collision_normal() == Vector3.UP:
			body.global_position.y = $LedgeHeightCheckRight.get_collision_point().y
			body.velocity.y = 0
			is_on_stairs = true
	return is_on_stairs
