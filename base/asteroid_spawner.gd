extends "spawner.gd"

export var available_sizes_range:Vector2
export var colors:Gradient

func init_obj(obj):
  .init_obj(obj)
  obj.anim.play('RESET')
  var size = lerp(available_sizes_range.x, available_sizes_range.y, randf())
  obj.init_asteroid(size, size * size, 20, colors.interpolate(randf()))
