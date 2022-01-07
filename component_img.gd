extends Node

export var img_root = ""
onready var top:Sprite = get_node(img_root + "top")
onready var base:Sprite = get_node(img_root + "base")
onready var comp_utils = get_node("/root/utils/component")

func set_component(type):
	var parts = comp_utils.get_component_parts(type)
	comp_utils.set_texture(top, parts[0])
	if len(parts) > 1:
		comp_utils.set_texture(base, parts[1])
	else:
		base.texture = null
