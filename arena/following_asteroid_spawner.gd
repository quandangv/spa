extends "res://base/asteroid_spawner.gd"

export(NodePath) var target

func _ready():
  target = get_node(target)
  spawn_rate = 0.2

func init_obj(asteroid):
  .init_obj(asteroid)
  asteroid.target = target
