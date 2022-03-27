extends Node2D

signal start_firing

onready var input = $input
onready var bot = $bot
onready var parent = get_parent()

var movement:Vector2
var firing:bool
var angle:float
const stop_multiplier = 1
const thrust_to_rotate_speed = 3

func _ready():
  input.connect("on_lost_input", self, "lost_input")
  input.connect("on_gained_input", self, "gained_input")
  input.parent = parent
  bot.parent = parent

func wake_up():
  bot.hibernate()
  input.wake_up()
  set_physics_process(true)

func hibernate():
  set_physics_process(false)
  input.hibernate()
  if bot.active:
    bot.hibernate()

func lost_input():
  bot.wake_up()
  bot.connect("start_firing", self, "emit_signal", ["start_firing"])
  input.disconnect("start_firing", self, "emit_signal")

func gained_input():
  if bot.active:
    bot.hibernate()
    bot.disconnect("start_firing", self, "emit_signal")
  set_physics_process(true)
  input.connect("start_firing", self, "emit_signal", ["start_firing"])

func import_controls(from):
  movement = from.movement
  angle = from.angle
  firing = from.firing

func _physics_process(delta):
  if input.have_input:
    import_controls(input)
  elif bot.active:
    import_controls(bot)
  else:
    movement = Vector2.ZERO
    firing = true
    emit_signal("start_firing")
    set_physics_process(false)
    
