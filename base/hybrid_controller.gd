extends Node2D

signal start_firing

onready var input = $input
onready var bot = $bot
onready var parent = get_parent()

var movement:Vector2
var firing:bool
var angle:float = PI
const stop_multiplier = 1
const thrust_to_rotate_speed = 3

func _ready():
  if Multiplayer.active and not is_network_master():
    input.queue_free()
    bot.queue_free()
    input = null
    bot = null
  else:
    input.connect("on_lost_input", self, "lost_input")
    input.connect("on_gained_input", self, "gained_input")
    input.parent = parent
    input.direct_control = false
    bot.parent = parent
  set_physics_process(false)

func wake_up():
  if bot and input:
    bot.wake_up()
    bot.hibernate()
    input.wake_up()
    set_physics_process(true)

func hibernate():
  if bot and input:
    set_physics_process(false)
    input.hibernate()
    if bot.active:
      bot.hibernate()

func lost_input():
  if bot and input:
    bot.wake_up()
    bot.connect("start_firing", self, "emit_start_firing")
    if input.is_connected("start_firing", self, "emit_start_firing"):
      input.disconnect("start_firing", self, "emit_start_firing")

func gained_input():
  if bot and input:
    if bot.active:
      bot.hibernate()
      bot.disconnect("start_firing", self, "emit_start_firing")
    set_physics_process(true)
    input.connect("start_firing", self, "emit_start_firing")

func import_controls(from):
  movement = from.movement
  angle = from.angle
  firing = from.firing

func _physics_process(delta):
  var source
  if input.have_input:
    source = input
    if Multiplayer.active:
      if source.movement != movement:
        rpc("set_movement", source.movement)
    else:
      movement = source.movement
  elif bot.active:
    source = bot
    if Multiplayer.active:
      rpc_unreliable("set_movement", source.movement)
    else:
      movement = source.movement
  else:
    if Multiplayer.active:
      rpc("set_movement", Vector2.ZERO)
      rpc("set_firing", true)
      rpc("set_start_firing")
    else:
      movement = Vector2.ZERO
      firing = true
      emit_signal("start_firing")
    set_physics_process(false)
    return
  if Multiplayer.active:
    if source.firing != firing:
      rpc("set_firing", source.firing)
    rpc_unreliable("set_angle", source.angle)
  else:
    firing = source.firing
    angle = source.angle

func emit_start_firing():
  if Multiplayer.active:
    rpc("set_start_firing")
  else:
    set_start_firing()

puppetsync func set_movement(value):
  movement = value
puppetsync func set_firing(value):
  firing = value
puppetsync func set_start_firing():
  emit_signal("start_firing")
puppetsync func set_angle(value):
  angle = value
