extends Area2D

signal start_firing
signal on_lost_input
signal on_gained_input

var movement:Vector2
var firing:bool
var angle:float
const stop_multiplier = 1
const thrust_to_rotate_speed = 3

var disabled:bool
var have_input:bool = false
const off_color = Color(0.5, 0.5, 0.5)
const mid_color = Color(0.8, 0.8, 0.8)
onready var camera = get_node("/root/game/camera")
onready var bg_modulate = get_node("/root/game/background/modulate")
onready var parent = get_parent()
var direct_control = true

func _ready():
  if not Multiplayer.active or is_network_master():
    connect("mouse_entered", self, "_mouse_entered")
    connect("mouse_exited", self, "update_color")
  else:
    input_pickable = false
  set_process(false)

func wake_up():
  disabled = false
  if not Multiplayer.active or is_network_master():
    $shape.shape.radius = parent.size
    if InputCoordinator.register_implicit_controller("ship", self, true):
      gained_input()
    else:
      lost_input()
  else:
    lost_input()

func hibernate():
  disabled = true
  InputCoordinator.unregister_implicit_controller(self)
  lost_input()

func _process(delta):
  var new_movement = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
  var new_firing = Input.is_action_pressed("fire")
  var new_angle = (self.get_global_mouse_position() - parent.global_position).angle()
  var new_start_firing = Input.is_action_just_pressed("fire")
  if Multiplayer.active and direct_control:
    if new_movement != movement:
      rpc("set_movement", new_movement)
    if new_firing != firing:
      rpc("set_firing", new_firing)
    rpc_unreliable("angle", new_angle)
    if new_start_firing:
      rpc("set_start_firing")
  else:
    movement = new_movement
    firing = new_firing
    angle = new_angle
    if new_start_firing:
      set_start_firing()

puppetsync func set_movement(value):
  movement = value
puppetsync func set_firing(value):
  firing = value
puppetsync func set_start_firing():
  emit_signal("start_firing")
puppetsync func set_angle(value):
  angle = value

func lost_input():
  if have_input:
    have_input = false
    set_process(false)
    parent.disconnect("bumped", self, "_bumped")
    parent.disconnect("explode", self, "_explode")
    camera.tracked_obj.erase(parent)
    movement = Vector2.ZERO
    firing = false
    emit_signal("on_lost_input")
  update_color()
  return true

func gained_input():
  if not have_input:
    have_input = true
    set_process(true)
    parent.connect("bumped", self, "_bumped")
    parent.connect("explode", self, "_explode")
    camera.tracked_obj.append(parent)
    emit_signal("on_gained_input")
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
      if have_input:
        if event.doubleclick:
          InputCoordinator.unregister_implicit_controller(self)
          lost_input()
      elif not disabled and InputCoordinator.register_implicit_controller("ship", self, event.doubleclick):
        gained_input()

func _mouse_entered():
  if not disabled:
    parent.color_modifier = mid_color
func update_color():
  parent.color_modifier = Color.white if have_input or not input_pickable else off_color

func _exit_tree():
  camera.tracked_obj.erase(parent)
