extends Camera2D

const adjustment_speed = 100
const mouse_adjustment_range = 0.4
const manual_adjustment_limit = [0.5, 2]
export(Array, NodePath) var tracked_obj
var manual_adjustment:Vector2
var have_inputs:bool = true
var screen_size_factor:float = 1
var manual_factor:float = 1
var shake:Vector2

func _ready():
  get_tree().connect("screen_resized", self, "_screen_resized")
  _screen_resized()
  if not InputCoordinator.register_implicit_controller("camera", self):
    lost_input()
  for i in range(len(tracked_obj)):
    if tracked_obj[i] is NodePath:
      tracked_obj[i] = get_node(tracked_obj[i])

func lost_input():
  have_inputs = false
  manual_adjustment = Vector2.ZERO
  last_track_offset = Vector2.ZERO
func gained_input():
  have_inputs = true

var last_track_offset:Vector2
func _process(delta):
  if tracked_obj:
    var center = Vector2.ZERO
    var count = 0
    for obj in tracked_obj:
      if obj.visible:
        count += 1
        center += obj.global_position
    var track_offset = center / count
    manual_adjustment += track_offset - last_track_offset
    last_track_offset = track_offset
  global_position = manual_adjustment + shake.rotated(randf()*PI*2)
  if have_inputs:
    manual_adjustment += Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")) * delta * adjustment_speed
  if shake != Vector2.ZERO:
    if shake.length_squared() < 0.001:
      shake = Vector2.ZERO
    shake = lerp(shake, Vector2.ZERO, delta*2)

func _input(event):
  if event is InputEventMouseMotion:
    var screen_size = get_viewport().size
    offset_h = lerp(-mouse_adjustment_range, mouse_adjustment_range, event.position.x / screen_size.x)
    offset_v = lerp(-mouse_adjustment_range, mouse_adjustment_range, event.position.y / screen_size.y)
  var factor = Input.get_axis("zoom_in", "zoom_out")
  if abs(factor) > 0.1:
    manual_factor = clamp(pow(1.1, factor) * manual_factor, manual_adjustment_limit[0], manual_adjustment_limit[1])
    set_zoom(manual_factor * screen_size_factor)

func _screen_resized():
  var screen_size = OS.window_size
  var factor = sqrt(100 / min(screen_size.x, screen_size.y))
  set_zoom(factor * manual_factor)
  screen_size_factor = factor

func set_zoom(value):
  zoom = Vector2(value, value)
