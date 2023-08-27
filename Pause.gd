extends CanvasLayer

onready var panel = $PopupPanel

# Called when the node enters the scene tree for the first time.
# func _ready():
# 	panel.popup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Unpause_pressed():
	get_tree().paused = false
	panel.hide()


func _on_Quit_pressed():
	get_tree().quit()

func _input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if panel.visible:
			panel.hide()
			get_tree().paused = false
		else:
			panel.show()
			get_tree().paused = true
