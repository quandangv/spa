extends Node2D

func get_position():
  return get_child(randi() % get_child_count()).get_position()
