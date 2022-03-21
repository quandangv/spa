extends Area2D

signal start_firing
var movement:Vector2
var firing:bool
var angle:float
var disabled:bool
const stop_multiplier = 1
const thrust_to_rotate_speed = 3
const off_color = Color(0.5, 0.5, 0.5)
const mid_color = Color(0.8, 0.8, 0.8)
onready var camera = get_node("/root/game/camera")
onready var bg_modulate = get_node("/root/game/background/modulate")
onready var parent = get_parent()

func _ready():
  parent.get_node("rank").visible = Storage.player["rank"] > 0
  parent.connect("bumped", self, "_bumped")
  parent.connect("explode", self, "_explode")
  connect("mouse_entered", self, "_mouse_entered")
  connect("mouse_exited", self, "update_color")

func wake_up():
  disabled = false
  $shape.shape.radius = parent.size
  if InputCoordinator.register_implicit_controller("ship", self):
    gained_input()
  else:
    lost_input()
  update_color()

func hibernate():
  disabled = true
  InputCoordinator.unregister_implicit_controller(self)
  lost_input()

func _unhandled_input(_event):
  movement = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
  firing = Input.is_action_pressed("fire")
  if Input.is_action_just_pressed("fire"):
    emit_signal("start_firing")
  angle = (self.get_global_mouse_position() - parent.global_position).angle()

func lost_input():
  set_process_input(false)
  set_process_unhandled_input(false)
  camera.tracked_obj.erase(parent)
  movement = Vector2.ZERO
  firing = false

func gained_input():
  set_process_input(true)
  set_process_unhandled_input(true)
  camera.tracked_obj.append(parent)
  parent.set_color(GameUtils.ship_colors["self"])

func _bumped(amount):
  camera.shake += amount

func _explode():
  bg_modulate.color.g *= 0.5
  bg_modulate.color.b *= 0.5
  camera.shake += Vector2(30, 0)

func _target_explode():
  bg_modulate.color *= 1.3

func _input_event(viewport, event, shape_idx):
  if event is InputEventMouseButton:
    if event.button_index == BUTTON_LEFT and event.pressed:
      if is_processing_input():
        if event.doubleclick:
          InputCoordinator.unregister_implicit_controller(self)
          lost_input()
          update_color()
      elif not disabled and InputCoordinator.register_implicit_controller("ship", self):
        gained_input()
        update_color()

func _mouse_entered():
  if not disabled:
    parent.color_modifier = mid_color
func update_color():
  parent.color_modifier = Color.white if is_processing_input() else off_color
