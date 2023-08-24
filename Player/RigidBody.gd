extends RigidBody2D

export var target_movement_time = 0.2
export var target_accel_time = 0.1
export var max_torque: float = 1000

func look_follow(current_position, target_position):
	var target_angle = atan2(target_position.y - current_position.y, target_position.x - current_position.x)
	var current_angle = rotation
	var difference = target_angle - current_angle

	if difference > PI:
		difference -= PI * 2
	elif difference < -PI:
		difference += PI * 2

	attempt_angular_velocity(difference / target_movement_time)

# func _integrate_forces(state):
func _physics_process(_delta):
	look_follow(global_position, get_global_mouse_position())

func attempt_angular_velocity(target_velocity: float):
	var target_acceleration = (target_velocity - angular_velocity) / target_accel_time
	var target_torque = inertia * target_acceleration
	add_torque(clamp(target_torque, -max_torque, max_torque))
