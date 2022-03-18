extends Button

export var resume_icon:Texture
var pause_icon

func _ready():
  pause_icon = icon

func pause_changed(paused):
  if paused:
    icon = resume_icon
    text = "RESUME"
  else:
    icon = pause_icon
    text = "PAUSE"
  get_tree().paused = paused
