extends Node2D

onready var player_body = $ShittyPlayer/RigidBody
onready var collide_audio = $CollideAudio

func _ready():
	player_body.connect("body_entered", self, "_on_ShittyPlayer_body_entered")

func _on_ShittyPlayer_body_entered(_body):
	var player_speed = player_body.linear_velocity.length()
	if not collide_audio.playing:
		var vol_offset = clamp(50 - player_speed, 0, 50) / 50
		collide_audio.volume_db = vol_offset * -18
		collide_audio.play()
