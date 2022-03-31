extends "res://game/target_selector.gd"

export var max_from_anchor:float = 200 # maximum distance from the anchor will we pursue a target
const max_keep_target_sqr = 4
onready var max_from_anchor_sqr = max_from_anchor*max_from_anchor
onready var anchored_position = parent.global_position

func _idle(delta):
  if anchored_position != null:
    var movement = anchored_position - parent.parent.global_position - parent.parent.linear_velocity
    var movement_length_sqr = movement.length_squared()
    if movement_length_sqr > 1:
      movement /= pow(movement_length_sqr, 0.2) *0.25
    parent.movement += movement
  parent.angle = parent.movement.angle()
  assert(not is_nan(parent.angle))

func before_combine_movement():
  if anchored_position != null and parent.target_obj != null:
    var from_anchor = (parent.global_position - anchored_position).length_squared() / max_from_anchor_sqr
    if from_anchor > 1:
      if from_anchor > max_keep_target_sqr:
        parent.target_obj = null
      else:
        parent.new_movement = (anchored_position - parent.parent.global_position - parent.parent.linear_velocity)

func _ready():
  parent.approach_bias = anchored_position
  parent.connect("idle", self, "_idle")
  parent.connect("before_combine_movement", self, "before_combine_movement")
