extends Node

export var thrust:float = 1
const thrust_to_torque = 1000
const thrust_to_force = 200
const min_movement_sqr = 0.001
onready var controller = get_node("../controller")
onready var parent = get_parent()

func move(direction, delta):
	assert(not is_nan(direction.x) and not is_nan(direction.y), "Controller movement is NAN")
	var sqr_length = direction.length_squared()
	if sqr_length < min_movement_sqr:
		direction = -parent.linear_velocity * parent.mass * controller.stop_multiplier
		sqr_length = direction.length_squared()
		if sqr_length == 0:
			return
		if sqr_length < pow(thrust * thrust_to_force * delta / parent.mass, 2):
			parent.linear_velocity = Vector2.ZERO
			return
	if sqr_length > 1:
		direction = direction.normalized()
	parent.apply_central_impulse(direction * thrust * thrust_to_force * delta)

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
