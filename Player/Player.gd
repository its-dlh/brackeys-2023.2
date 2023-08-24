extends Node2D

export var max_throw_distance = 300
export var throw_speed = 400
export var anchor_slack = 10

onready var rigid_body = $RigidBody
onready var anchor = $Anchor

var hook_state = HookStates.idle
var is_pinned = false
var anchor_pin: PinJoint2D = null

enum HookStates {
	idle,
	extended,
	stuck
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	if anchor.position.distance_to(rigid_body.position) > max_throw_distance and hook_state != HookStates.stuck and not is_pinned:
		is_pinned = true
		anchor_pin = PinJoint2D.new()
		anchor_pin.position = rigid_body.position
		anchor_pin.node_a = rigid_body.get_path()
		anchor_pin.node_b = anchor.get_path()

		add_child(anchor_pin)

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if hook_state == HookStates.idle:
			hook_state = HookStates.extended
			var impulse_vector = Vector2(throw_speed, 0).rotated(rigid_body.rotation)
			anchor.apply_impulse(Vector2(), impulse_vector)


func _on_Anchor_body_entered(body):
	if (hook_state == HookStates.extended):
		hook_state = HookStates.stuck
		anchor.sleeping = true
		var chain = DampedSpringJoint2D.new()
		chain.stiffness = 0
		chain.damping = 0
		chain.position = rigid_body.position
		chain.rest_length = rigid_body.position.distance_to(body.position)
		chain.length = chain.rest_length + anchor_slack
		chain.rotation = rad2deg(rigid_body.position.angle_to(body.position))
		chain.node_a = rigid_body.get_path()
		chain.node_b = body.get_path()

		add_child(chain)


