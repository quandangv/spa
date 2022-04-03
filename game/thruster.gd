extends Node2D

export var thrust:float = 1
const thrust_to_torque = 1500
const thrust_to_force = 300
const min_movement = 0.01
const modulate_factor = 0.1
var move_direction:Vector2
var move_strength:float
onready var controller = get_node("../controller")
onready var parent = get_parent()
onready var particles = $particles

func _ready():
  init(thrust)
func _draw():
  var color = Color.white
  draw_circle(Vector2.ZERO, thrust, color)
  draw_rect(Rect2(0, -thrust, thrust, thrust*2), color, true)

func move(direction, delta):
  move_direction = direction
  var move_strength = move_direction.length()
  if move_strength < min_movement: # if user give no input
    move_direction = -parent.linear_velocity * controller.stop_multiplier
    move_strength = move_direction.length()
    if move_strength != 0 and move_strength < thrust * thrust_to_force * delta / parent.mass:
      parent.linear_velocity = Vector2.ZERO
      move_strength = 0
  if move_strength >= 0.99: # if user input is out of bound
    move_direction = move_direction.normalized()
    move_strength = 1
  move_direction *= exp(-move_direction.dot(parent.linear_velocity.normalized())*0.5)
  
  if move_strength > 0.1: # if there is any input after everything
    rotation = lerp_angle(rotation, (-move_direction).angle() - parent.global_rotation, 0.05)
  particles.emitting = randf() < move_strength
  if move_strength > 0:
    parent.apply_central_impulse(move_direction * thrust * thrust_to_force * delta)

func init(thrust):
  particles.speed_scale = thrust*2
  particles.modulate = Color(1, 1, 1, modulate_factor * thrust)
  self.thrust = thrust
  visible = thrust > 0
  update()

func _physics_process(delta):
  if thrust > 0 and controller:
    assert(not is_nan(controller.movement.x) and not is_nan(controller.movement.y), "Controller movement is NAN")
    if is_nan(controller.movement.x) or is_nan(controller.movement.y):
      controller.movement = Vector2.ZERO
    move(controller.movement, delta)
    assert(not is_nan(controller.angle), "Controller angle is NAN")
    if is_nan(controller.angle):
      controller.angle = 0
    var rotation_delta = controller.angle - parent.global_rotation
    if rotation_delta < -PI:
      rotation_delta += PI*2
    elif rotation_delta > PI:
      rotation_delta -= PI*2
    var target_angular_velocity = rotation_delta * thrust * controller.thrust_to_rotate_speed
    var angular_delta = target_angular_velocity - parent.angular_velocity
    parent.apply_torque_impulse(clamp(angular_delta * parent.mass, -1, 1) * thrust * thrust_to_torque * delta)
