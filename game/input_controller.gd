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
  if not GameUtils.networking or is_network_master():
    parent.connect("bumped", self, "_bumped")
    parent.connect("explode", self, "_explode")
    parent.get_node("rank").visible = Storage.player["rank"] > 0
    connect("mouse_entered", self, "_mouse_entered")
    connect("mouse_exited", self, "update_color")

func wake_up():
  disabled = false
  if not GameUtils.networking or is_network_master():
    parent.set_color(GameUtils.ship_colors["self"])
    $shape.shape.radius = parent.size
    if InputCoordinator.register_implicit_controller("ship", self):
      gained_input()
    else:
      lost_input()
      update_color()
  else:
    lost_input()

func hibernate():
  disabled = true
  InputCoordinator.unregister_implicit_controller(self)
  lost_input()

func _process(delta):
  register_input("movement", Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")))
  register_input("firing", Input.is_action_pressed("fire"))
  if Input.is_action_just_pressed("fire"):
    if GameUtils.networking:
      rpc("set_start_firing")
    else:
      set_start_firing()
  register_input("angle", (self.get_global_mouse_position() - parent.global_position).angle())

func register_input(name, value):
  if GameUtils.networking:
    if value != get(name):
      rpc("set_" + name, value)
  else:
    set(name, value)

puppetsync func set_movement(value):
  movement = value
puppetsync func set_firing(value):
  firing = value
puppetsync func set_start_firing():
  emit_signal("start_firing")
puppetsync func set_angle(value):
  angle = value

func lost_input():
  set_process(false)
  camera.tracked_obj.erase(parent)
  movement = Vector2.ZERO
  firing = false

func gained_input():
  set_process(true)
  camera.tracked_obj.append(parent)
  update_color()

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
      if is_processing():
        if event.doubleclick:
          InputCoordinator.unregister_implicit_controller(self)
          lost_input()
          update_color()
      elif not disabled and InputCoordinator.register_implicit_controller("ship", self, event.doubleclick):
        gained_input()

func _mouse_entered():
  if not disabled:
    parent.color_modifier = mid_color
func update_color():
  parent.color_modifier = Color.white if is_processing() else off_color

func _exit_tree():
  camera.tracked_obj.erase(parent)
