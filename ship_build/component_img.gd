extends Node

export var img_root = ""
onready var top:Sprite = get_node(img_root + "top")
onready var base:Sprite = get_node(img_root + "base")

func set_component(type):
  var parts = ComponentUtils.get_component_parts(type)
  ComponentUtils.set_texture(top, parts[0])
  if len(parts) > 1:
    ComponentUtils.set_texture(base, parts[1])
  else:
    base.texture = null
