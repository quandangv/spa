extends Label

func _ready():
  SceneLoader.play_scene_music("main_menu")
func play():
  SceneLoader.fade_load("main_menu", "intro")
