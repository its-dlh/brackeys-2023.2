extends Node2D

export var max_throw_distance = 150
# export var throw_speed = 400
# export var anchor_slack = 10

onready var rigid_body = $RigidBody
onready var anchor_line = $AnchorLine
onready var pin_anchor = StaticBody2D.new()
onready var splash_down_audio = $SplashDownAudio
onready var splash_up_audio = $SplashUpAudio

var hook_state = HookStates.idle
var is_pinned = false
var anchor_pin: PinJoint2D = null

enum HookStates {
	idle,
	extended,
	stuck
}

func _physics_process(_delta):
	if hook_state == HookStates.extended:
		var space_state = get_world_2d().direct_space_state
		var ray_vector = Vector2(max_throw_distance, 0).rotated(rigid_body.rotation)
		var origin = rigid_body.global_position

		var ray_result = space_state.intersect_ray(origin, origin + ray_vector, [], 2)

		anchor_line.global_position = origin
		anchor_line.visible = true

		if ray_result:
			hook_state = HookStates.stuck
			print("stuck")

			pin_anchor.position = ray_result.position
			add_child(pin_anchor)

			anchor_pin = PinJoint2D.new()
			anchor_pin.position = rigid_body.position
			anchor_pin.node_a = rigid_body.get_path()
			anchor_pin.node_b = pin_anchor.get_path()

			add_child(anchor_pin)

			anchor_line.points = [Vector2(0, 0), ray_result.position - origin]
		else:
			anchor_line.points = [Vector2(0, 0), ray_vector]

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if hook_state == HookStates.idle:
			hook_state = HookStates.extended
			print("extended")

		else:
			if hook_state == HookStates.stuck:
				remove_child(anchor_pin)
				anchor_pin.queue_free()
				remove_child(pin_anchor)

				# var impulse_vector = rigid_body.global_position - pin_anchor.global_position
				var impulse_vector = Vector2(200, 0).rotated(rigid_body.global_rotation)
				rigid_body.apply_impulse(Vector2(), impulse_vector)

			hook_state = HookStates.idle
			print("idle")
			anchor_line.visible = false

func _on_Water_body_entered(_body):
	if rigid_body.linear_velocity.y > 30:
		var vol_offset = clamp(120 - rigid_body.linear_velocity.y, 0, 100) / 100
		splash_down_audio.volume_db = vol_offset * -20
		splash_down_audio.play()

func _on_Water_body_exited(_body):
	if rigid_body.linear_velocity.y < -30:
		var vol_offset = clamp(-120 - rigid_body.linear_velocity.y, -100, 0) / 100
		splash_up_audio.volume_db = vol_offset * 20
		splash_up_audio.play()
