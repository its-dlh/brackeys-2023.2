extends Node2D

export var max_throw_distance = 100
# export var throw_speed = 400
# export var anchor_slack = 10

onready var rigid_body = $RigidBody
onready var anchor_line = $AnchorLine
onready var pin_anchor = StaticBody2D.new()

var hook_state = HookStates.idle
var is_pinned = false
var anchor_pin: PinJoint2D = null

enum HookStates {
	idle,
	extended,
	stuck
}

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	pass

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

			hook_state = HookStates.idle
			print("idle")
			anchor_line.visible = false


# func _on_Anchor_body_entered(body):
# 	if (hook_state == HookStates.extended):
# 		hook_state = HookStates.stuck
# 		anchor.sleeping = true
# 		var chain = DampedSpringJoint2D.new()
# 		chain.stiffness = 0
# 		chain.damping = 0
# 		chain.position = rigid_body.position
# 		chain.rest_length = rigid_body.position.distance_to(body.position)
# 		chain.length = chain.rest_length + anchor_slack
# 		chain.rotation = rad2deg(rigid_body.position.angle_to(body.position))
# 		chain.node_a = rigid_body.get_path()
# 		chain.node_b = body.get_path()

# 		add_child(chain)


