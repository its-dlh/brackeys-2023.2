extends Node2D

var anchor_scene = preload("./Anchor.tscn")

export var max_throw_distance = 300
export var throw_speed = 400
export var anchor_slack = 10

onready var rigid_body = $RigidBody
# onready var anchor = $Anchor

var hook_state = HookStates.idle
var is_pinned = false
var anchor = null
var anchor_pin: PinJoint2D = null

enum HookStates {
	idle,
	extending,
	extended,
	stuck,
	retracting
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _integrate_forces(state):
	if hook_state == HookStates.extending:
		anchor.position = rigid_body.position
		hook_state = HookStates.extended

		var impulse_vector = Vector2(throw_speed, 0).rotated(rigid_body.rotation)
		anchor.integrate_forces(state)
		anchor.apply_impulse(Vector2(), impulse_vector)

func _physics_process(delta):
	if hook_state == HookStates.extended and anchor.position.distance_to(rigid_body.position) > max_throw_distance and not is_pinned:
		print("pinned")
		is_pinned = true
		anchor_pin = PinJoint2D.new()
		anchor_pin.position = rigid_body.position
		anchor_pin.node_a = rigid_body.get_path()
		anchor_pin.node_b = anchor.get_path()

		add_child(anchor_pin)

	# if hook_state == HookStates.extending: # and Input.is_mouse_button_pressed(BUTTON_LEFT):
		# hook_state = HookStates.extended
		# var impulse_vector = Vector2(throw_speed, 0).rotated(rigid_body.rotation)
		# anchor.apply_impulse(Vector2(), impulse_vector)

	if hook_state == HookStates.retracting:
		hook_state = HookStates.idle

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if hook_state == HookStates.idle:
			hook_state = HookStates.extending
			anchor = anchor_scene.instance()
			print("created")
			anchor.global_position = rigid_body.global_position
			get_parent().add_child(anchor)
			anchor.connect("body_entered", self, "_on_Anchor_body_entered")
		else:
			hook_state = HookStates.retracting
			anchor.sleeping = true
			get_parent().remove_child(anchor)
			anchor.queue_free()
			anchor = null


func _on_Anchor_body_entered(body):
	if (hook_state == HookStates.extended):
		print("collided")
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


