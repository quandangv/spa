extends Node

onready var check_timer = $enemy_check
onready var parent = get_parent()

const keep_target_preference = 70 # preference to keep the target even when there are nearer targets

func target_condition(obj):
  return obj.is_inside_tree() and obj.side != 'junk'

func check_enemy():
  var bodies = parent.detector.get_overlapping_bodies()
  var min_dists = {}
  var chosen_bodies = {}
  for body in bodies:
    if body != parent and GameUtils.is_enemy(parent.parent.side, body) and target_condition(body):
      var dist = (body.global_position - parent.parent.global_position).length_squared()
      if body == parent.target_obj:
        dist -= keep_target_preference / max(parent.thrust, 1)
      var rank = parent.get_target_rank(body)
      if rank in min_dists:
        var min_dist = min_dists[rank]
        if dist >= min_dist:
          continue
      min_dists[rank] = dist
      chosen_bodies[rank] = body
  for i in range(parent.max_rank):
    var new_target = chosen_bodies.get(i)
    if new_target:
      parent.set_target(new_target)
      return

func _ready():
  check_timer.wait_time = 0.2
  check_timer.connect("timeout", self, "check_enemy")
  parent.connect("hibernate", check_timer, "stop")
  parent.connect("wake_up", check_timer, "start")
  parent.connect("wake_up", self, "check_enemy")
  parent.connect("target_removed", self, "check_enemy")
