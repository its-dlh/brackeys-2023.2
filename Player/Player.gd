extends RigidBody2D

enum PlayerStates {DEFAULT, HOOKED}
enum HookStates {NONE, EXTEND, RETRACT_TO_PLAYER}

export var throw_speed = 0.5
export var target_movement_time = 0.2
export var target_accel_time = 0.1
export var max_torque: float = 1000

onready var hook = $Anchor
onready var hook_shape := $Anchor/CollisionShape2D

const HOOK_MAX_LENGTH = 250.0
const HOOK_SPEED = 800.0
const PLAYER_HOOK_SPEED = 600.0

var hook_direction: Vector2
var player_state = PlayerStates.DEFAULT
var hook_state = HookStates.NONE

func _physics_process(delta):
	look_follow(global_position, get_global_mouse_position())
	
	match player_state:
		PlayerStates.DEFAULT:
			hook.show()
		PlayerStates.HOOKED:
			var collision = get_colliding_bodies()
			if not collision.empty():
				player_state = PlayerStates.DEFAULT
				hide_hook()
			elif global_position.distance_to(hook.global_position) <= PLAYER_HOOK_SPEED * delta:
				global_position = hook.global_position
				player_state = PlayerStates.DEFAULT
				hide_hook()
	match hook_state:
		HookStates.EXTEND:
			var collision_info = hook.move_and_collide(hook_direction * HOOK_SPEED * delta)
			if collision_info:
				hook_collide()
			if hook.global_position.distance_to(global_position) >= HOOK_MAX_LENGTH:
				hook_state = HookStates.RETRACT_TO_PLAYER
				hook_shape.call_deferred("set_disabled", true)
		HookStates.RETRACT_TO_PLAYER:
			var direction = hook.global_position.direction_to(global_position + Vector2(20, 20))
			var collision_info = hook.move_and_collide(direction * HOOK_SPEED * delta)
			if collision_info:
				hook_state = HookStates.NONE
				hide_hook()

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if hook_state == HookStates.NONE:
			hook.global_position = global_position + Vector2(20, 20) # center it
			hook_state = HookStates.EXTEND
			hook_direction = Vector2(throw_speed, 0).rotated(rotation)
			hook.show()
			hook_shape.disabled = false

func hook_collide():
	player_state = PlayerStates.HOOKED
	apply_impulse(Vector2.ZERO, global_position.direction_to(hook.global_position) * PLAYER_HOOK_SPEED)
	hook_state = HookStates.NONE
	hook_shape.call_deferred("set_disabled", true)

func look_follow(current_position, target_position):
	var target_angle = atan2(target_position.y - current_position.y, target_position.x - current_position.x)
	var current_angle = rotation
	var difference = target_angle - current_angle

	if difference > PI:
		difference -= PI * 2
	elif difference < -PI:
		difference += PI * 2

	attempt_angular_velocity(difference / target_movement_time)

func attempt_angular_velocity(target_velocity: float):
	var target_acceleration = (target_velocity - angular_velocity) / target_accel_time
	var target_torque = inertia * target_acceleration
	add_torque(clamp(target_torque, -max_torque, max_torque))

func hide_hook():
	hook.hide()
	hook_shape.call_deferred("set_disabled", true)
