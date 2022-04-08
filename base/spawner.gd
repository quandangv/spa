extends Node2D

export var autostart:bool = true
onready var pool = $pool
var positioner
var spawn_rate:float = 5

func _process(delta):
  if randf() < spawn_rate * delta:
    var obj = pool.get_object()
    init_obj(obj)

func _ready():
  if not autostart:
    hibernate()
  positioner = get_node_or_null("positioner")

func hibernate():
  set_process(false)
func wake_up():
  set_process(true)

func init_obj(obj):
  obj.wake_up()
  obj.global_position = positioner.get_position()
