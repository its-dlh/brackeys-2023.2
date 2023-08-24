extends Node2D

export var max_throw_distance = 200
export var throw_speed = 400

onready var rigid_body = $RigidBody
onready var anchor = $Anchor

var hook_state = HookStates.idle
var is_pinned = false

enum HookStates {
	idle,
	extended,
	stuck
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	if anchor.position.distance_to(rigid_body.position) > max_throw_distance and not is_pinned:
		is_pinned = true
		var pin = PinJoint2D.new()
		pin.position = rigid_body.position
		pin.node_a = rigid_body.get_path()
		pin.node_b = anchor.get_path()

		add_child(pin)

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed and hook_state == HookStates.idle:
		hook_state = HookStates.extended
		var impulse_vector = Vector2(throw_speed, 0).rotated(rigid_body.rotation)
		anchor.apply_impulse(Vector2(), impulse_vector)

func _on_Anchor_body_entered(body):
	hook_state = HookStates.stuck
	anchor.sleeping = true
	var chain = DampedSpringJoint2D.new()
	chain.position = rigid_body.position
	chain.length = rigid_body.position.distance_to(body.position)
	chain.rotation = rad2deg(rigid_body.position.angle_to(body.position))
	chain.node_a = rigid_body.get_path()
	chain.node_b = body.get_path()

	add_child(chain)
