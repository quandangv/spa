extends "res://base/asteroid.gd"

var target:Node2D
const thrust = 4
const thrust_to_rotate_speed =1
const thrust_to_torque = 500
const thrust_to_force = 20
const force_to_speed = 1

func init_points():
  var side_count = round(4*sqrt(size))
  var step = PI / side_count
  points.resize(side_count+3)
  line_points.resize(side_count+4)
  for i in range(side_count):
    points[i] = Vector2(size, 0).rotated(i * step - PI/2)
  points[side_count] = Vector2(size, 0).rotated(PI/2)
  points[side_count+1] = Vector2(-size, size)
  points[side_count+2] = Vector2(-size, -size)
  for i in range(len(points)):
    line_points[i] = points[i]
  line_points[side_count+3] = points[0]

func _physics_process(delta):
  var velocity = get("linear_velocity")
  var diff = target.global_position - global_position
  var mass = get("mass")
  var target_angle = (diff - velocity.project(diff.tangent()) * 2 - velocity*0.1).angle()
  var rotation_delta = target_angle - global_rotation
  if rotation_delta < -PI:
    rotation_delta += PI*2
  elif rotation_delta > PI:
    rotation_delta -= PI*2
  var target_angular_velocity = rotation_delta * thrust * thrust_to_rotate_speed
  var angular_delta = target_angular_velocity - get("angular_velocity")
  call("apply_torque_impulse", clamp(angular_delta * mass, -1, 1) * thrust * thrust_to_torque * delta)
  
  if diff.normalized().dot(velocity) < thrust * thrust_to_force * force_to_speed:
    call("apply_central_impulse", Vector2.RIGHT.rotated(global_rotation) * thrust * thrust_to_force * delta * mass)

func wake_up():
  .wake_up()
  $particles.restart()
