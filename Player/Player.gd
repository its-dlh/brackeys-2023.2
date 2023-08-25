extends RigidBody2D

enum PlayerStates {DEFAULT, HOOKED}
enum HookStates {NONE, EXTEND, RETRACT_TO_PLAYER}

export var target_movement_time = 0.2
export var target_accel_time = 0.1
export var max_torque: float = 1000

onready var hook = $Anchor
onready var hook_shape := $Anchor/CollisionShape2D

const HOOK_MAX_LENGTH = 600.0
const HOOK_SPEED = 800.0
const PLAYER_HOOK_SPEED = 600.0

var hook_direction: Vector2
var player_state = PlayerStates.DEFAULT
var hook_state = HookStates.NONE

func _physics_process(delta):
	look_follow(global_position, get_global_mouse_position())
	
	match player_state:
		PlayerStates.DEFAULT:
			pass
		PlayerStates.HOOKED:
			var collision = get_colliding_bodies()
			if not collision.empty():
				player_state = PlayerStates.DEFAULT
				hide_hook()
			elif global_position.distance_to(hook.global_position) <= PLAYER_HOOK_SPEED * delta:
				global_position = hook.global_position
				player_state = PlayerStates.DEFAULT
				hide_hook()
			if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
				player_state = PlayerStates.DEFAULT
				hook_state = HookStates.RETRACT_TO_PLAYER
			if Input.is_action_pressed("ui_up"):
				player_state = PlayerStates.DEFAULT
				hook_state = HookStates.RETRACT_TO_PLAYER
	match hook_state:
		HookStates.EXTEND:
			hook.global_position += hook_direction * HOOK_SPEED * delta
			if hook.global_position.distance_to(global_position) >= HOOK_MAX_LENGTH:
				hook_state = HookStates.RETRACT_TO_PLAYER
				hook_shape.call_deferred("set_disabled", true)
		HookStates.RETRACT_TO_PLAYER:
			hook.global_position += hook.global_position.direction_to(global_position) * HOOK_SPEED * delta
			if hook.global_position.distance_to(global_position) <= HOOK_SPEED * delta:
				hook_state = HookStates.NONE
				hide_hook()

func _on_Anchor_body_entered(_body):
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
