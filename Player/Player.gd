extends RigidBody2D

enum PlayerStates {DEFAULT, HOOKED}
enum HookStates {NONE, EXTEND, HOOKED, RETRACT_TO_PLAYER}

export var throw_speed = 0.5
export var target_movement_time = 0.2
export var target_accel_time = 0.1
export var max_torque: float = 1000

onready var anchor_point = $Position2D
onready var hook = $Position2D/Anchor
onready var hook_shape := $Position2D/Anchor/CollisionShape2D

onready var splash_down_audio = $SplashDownAudio
onready var splash_up_audio = $SplashUpAudio

const HOOK_MAX_LENGTH = 250.0
const HOOK_SPEED = 800.0
const PLAYER_HOOK_SPEED = 600.0

var anchor_sticky_position: Vector2
var hook_direction: Vector2
var player_state = PlayerStates.DEFAULT
var hook_state = HookStates.NONE

func _physics_process(delta):
	look_follow(global_position, get_global_mouse_position())

	if Input.is_action_pressed("left_click"):
		if player_state == PlayerStates.HOOKED:
			var direction = global_position.direction_to(hook.global_position)
			apply_impulse(Vector2.ZERO, global_position.direction_to(hook.global_position) * PLAYER_HOOK_SPEED * delta)
			if global_position.distance_to(hook.global_position) <= PLAYER_HOOK_SPEED * delta:
				global_position = hook.global_position
				player_state = PlayerStates.DEFAULT
				hide_hook()
		else:
			if hook_state == HookStates.RETRACT_TO_PLAYER or hook_state == HookStates.HOOKED:
				var direction = hook.global_position.direction_to(anchor_point.global_position)
				hook.move_and_collide(direction * HOOK_SPEED * delta)
				# We don't like the collision event as it returns (since the anchor
				# can knock around the Sub and cause a fun (but BAD) launch effect,
				# so instead we just process the distance and give ourselves a little
				# wiggle room with the constant
				if hook.global_position.distance_to(anchor_point.global_position) <= 1:
					hook_return()

	match hook_state:
		HookStates.EXTEND:
			if hook.global_position.distance_to(anchor_point.global_position) >= HOOK_MAX_LENGTH:
				# Too far!
				hook_state = HookStates.RETRACT_TO_PLAYER
			else:
				var collision_info = hook.move_and_collide(hook_direction * HOOK_SPEED * delta)
				if collision_info:
					hooked()
		HookStates.HOOKED:
			hook.global_position = anchor_sticky_position

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if hook_state == HookStates.NONE:
			hook_launch()

# When the user initially clicks the hook is launched
# Requires checking hook status before firing
func hook_launch():
	hook.global_position = anchor_point.global_position # center it
	hook_state = HookStates.EXTEND
	hook_direction = Vector2(throw_speed, 0).rotated(rotation)
	hook.show()
	hook_shape.disabled = false

# When the hook hits a target
func hooked():
	# We pause the movement of the anchor by collecting it's
	# position when it hits. In our physics processing, we reset
	# its position to the saved position

	# This is better than doing any kind of pause/disable since
	# we still want the anchor to process events
	anchor_sticky_position = hook.global_position
	player_state = PlayerStates.HOOKED
	hook_state = HookStates.HOOKED

	# We do want to keep from registering a second collision, however
	hook_shape.call_deferred("set_disabled", true)

# Hook returns to ship
func hook_return():
	print("hook return to ship")
	hook_state = HookStates.NONE
	player_state = PlayerStates.DEFAULT
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

func _on_Water_body_entered(_body):
	if linear_velocity.y > 30:
		var vol_offset = clamp(120 - linear_velocity.y, 0, 100) / 100
		splash_down_audio.volume_db = vol_offset * -20
		splash_down_audio.play()


func _on_Water_body_exited(_body):
	if linear_velocity.y < -30:
		var vol_offset = clamp(-120 - linear_velocity.y, -100, 0) / 100
		splash_up_audio.volume_db = vol_offset * 20
		splash_up_audio.play()
