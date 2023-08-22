extends RigidBody2D


func look_follow(state, current_position, target_position):
	var target_angle: int = rad2deg( atan2(target_position.y - current_position.y, target_position.x - current_position.x) )
	var current_angle: int = rotation_degrees
	var difference = (target_angle - current_angle + 180) % 360 - 180

	state.set_angular_velocity(difference * 1)

func _integrate_forces(state):
	look_follow(state, global_position, get_global_mouse_position())
