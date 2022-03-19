extends Node2D

onready var parent = get_parent().get_parent()
func _ready():
  parent.connect("design_loaded", self, "_load")
  $selector.connect("input_event", self, "_input_event")

func _load():
  $selector/shape.shape.radius = parent.size*1.5
