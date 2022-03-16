extends Node2D

export var latency = 0.1
var target_pos: Vector2
var target_rotation: float
var target_modulate: Color

func _process(delta):
  var weight = delta / latency
  position = lerp(position, target_pos, weight)
  rotation = lerp_angle(rotation, target_rotation, weight)
  modulate = lerp(modulate, target_modulate, weight)
