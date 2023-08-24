extends Node2D

var is_stuck: bool = false
onready var RigidPlayer: RigidBody2D = $RigidPlayer
onready var hook: RigidBody2D = $Anchor
onready var chain: DampedSpringJoint2D = $Chain

enum HookStates {
	idle,
	extended,
	stuck
}

enum HookStates {
	idle,
	extended,
	stuck
}

func _ready():
	chain.pause_mode = Node.PAUSE_MODE_STOP

func _physics_process(delta):
	# hook.look_at(get_global_mouse_position())
	pass

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		var impulse_vector = Vector2(500, 0).rotated(rotation)
		hook.apply_impulse(Vector2(), impulse_vector)
		print("click")


func _on_Anchor_body_entered(body):
	print(body)
	print("body entered")
	# process the collision
	chain.pause_mode = Node.PAUSE_MODE_PROCESS
