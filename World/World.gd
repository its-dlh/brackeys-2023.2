extends Node2D

onready var player = $Player
onready var collide_audio = $CollideAudio

func _on_Player_body_entered(body):
	var player_speed = player.linear_velocity.length()
	# print(player_speed)
	if not collide_audio.playing:
		var vol_offset = clamp(50 - player_speed, 0, 50) / 50
		collide_audio.volume_db = vol_offset * -18
		collide_audio.play()
