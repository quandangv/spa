extends Node2D

onready var pool = $pool
export var plasma_size:float

func get_plasma(side, hp, damage, position, velocity):
  var plasma = pool.get_object()
  plasma.anim.play('RESET')
  plasma.global_position = position
  plasma.damage = damage
  plasma.side = side
  plasma.color = GameUtils.side_colors.get(side, Color.gray)
  plasma.init_plasma(plasma_size, velocity, hp)
  return plasma
