extends "res://game/target_selector.gd"

export var max_from_anchor:float = 200 # maximum distance from the anchor will we pursue a target
onready var max_from_anchor_sqr = max_from_anchor*max_from_anchor
onready var anchored_position = parent.global_position

func _idle(delta):
  if anchored_position != null:
    parent.movement += (anchored_position - parent.parent.global_position - parent.parent.linear_velocity)
  parent.angle = parent.movement.angle()

func before_combine_movement():
  if anchored_position != null and parent.target_obj == null or (parent.target_obj.global_position - anchored_position).length_squared() > max_from_anchor_sqr:
    parent.new_movement = (anchored_position - parent.parent.global_position - parent.parent.linear_velocity)

func _ready():
  parent.approach_bias = anchored_position
  parent.connect("idle", self, "_idle")
  parent.connect("before_combine_movement", self, "before_combine_movement")
