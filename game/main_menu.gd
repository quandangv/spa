extends Label

export var scene_loader:NodePath

func play():
	get_node(scene_loader).load_scene("res://game/intro_scene.tscn")
