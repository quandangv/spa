extends "res://game/target_selector.gd"

export var max_from_anchor:float = 200 # maximum distance from the anchor will we pursue a target
onready var max_from_anchor_sqr = max_from_anchor*max_from_anchor
onready var anchored_position = parent.global_position

func target_condition(obj):
  var dist = (obj.global_position - anchored_position).length_squared()
  return .target_condition(obj) and dist <= max_from_anchor_sqr

func _process(delta):
  if parent.target_obj != null and (parent.target_obj.global_position - anchored_position).length_squared() > max_from_anchor_sqr:
    parent.remove_target()

func _idle(delta):
  if anchored_position != null:
    parent.movement += (anchored_position - parent.parent.global_position - parent.parent.linear_velocity)
  parent.angle = parent.movement.angle()

func _ready():
  parent.approach_bias = anchored_position
  parent.connect("idle", self, "_idle")
