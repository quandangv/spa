extends Node2D

export var thrust:float = 1
const thrust_to_torque = 1500
const thrust_to_force = 300
const min_movement = 0.01
onready var controller = get_node("../controller")
onready var parent = get_parent()
onready var particles = $particles

func _ready():
  init(thrust)
func _draw():
  var color = Color.darkgray
  draw_circle(Vector2.ZERO, thrust, color)
  draw_rect(Rect2(0, -thrust, thrust, thrust*2), color, true)

func move(direction, delta):
  assert(not is_nan(direction.x) and not is_nan(direction.y), "Controller movement is NAN")
  var length = direction.length()
  if length < min_movement:
    direction = -parent.linear_velocity * parent.mass * controller.stop_multiplier
    length = direction.length()
    if length != 0 and length < thrust * thrust_to_force * delta / parent.mass:
      parent.linear_velocity = Vector2.ZERO
      length = 0
  if length >= 0.99:
    direction = direction.normalized()
    length = 1
  if length > 0.1:
    rotation = lerp_angle(rotation, (-direction).angle() - parent.rotation, 0.05)
  particles.emitting = randf() < length
  if length > 0:
    parent.apply_central_impulse(direction * thrust * thrust_to_force * delta)

func init(thrust):
  particles.speed_scale = thrust
  self.thrust = thrust
  visible = thrust > 0
  update()

func _physics_process(delta):
  if thrust > 0:
    move(controller.movement, delta)
    assert(not is_nan(controller.angle), "Controller angle is NAN")
    var rotation_delta = controller.angle - parent.rotation
    if rotation_delta < -PI:
      rotation_delta += PI*2
    elif rotation_delta > PI:
      rotation_delta -= PI*2
    var target_angular_velocity = rotation_delta * thrust * controller.thrust_to_rotate_speed
    var angular_delta = target_angular_velocity - parent.angular_velocity
    parent.apply_torque_impulse(clamp(angular_delta * parent.mass, -1, 1) * thrust * thrust_to_torque * delta)
