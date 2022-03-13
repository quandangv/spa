extends "base_bot_controller.gd"

signal start_firing
var movement:Vector2
const firing = false
var angle:float
const stop_multiplier = 1
const thrust_to_rotate_speed = 3

var target_obj = null
var target_rank:int
var thrust:float
var waited:float
var current_firing_wait:float
var target_speed:Vector2
var bullet_speed_approx:float
var turret_count:int
onready var check_timer = $enemy_check

export var max_from_anchor:float = 200 # maximum distance from the anchor will we pursue a target
var max_from_anchor_sqr
var firing_wait = 0.7 # time to wait for turret to cool before firing again
var firing_wait_random = 4 # randomize waiting time for unpredictability
const firing_angle = 0.4 # multiplier of the acceptable turret angular precision to fire
const distance_kept = [6, 3] # distance to keep from the target instead of heabutting them
const base_bullet_speed = 8 # used along with turret stats to calculate approximate bullet speed
const keep_target_preference = 70 # preference to keep the target even when there are nearer targets
const strafe_force = [70, 0]

func remove_target():
	target_obj = null
	check_enemy()

func on_turret_load():
	"""Extract the stats from our ship for better extrapolation"""
	turret_count = 0
	var avg_turret_speed = 0
	var avg_turret_cooldown = 1
	for turret in parent.turrets:
		if abs(turret.rotation) < 0.001 and not is_nan(turret.reload_time):
			turret_count += 1
			avg_turret_speed += turret.base_speed
			avg_turret_cooldown += turret.turret_cooldown_speed
	if turret_count:
		avg_turret_speed /= turret_count
		avg_turret_cooldown /= turret_count
		bullet_speed_approx = base_bullet_speed * avg_turret_speed
		firing_wait = 6 / avg_turret_cooldown
		set_physics_process(true)
		set_process(true)
		check_timer.start()
	else:
		hibernate()
	thrust = parent.get_node('thruster').thrust

func _ready():
	check_timer.wait_time = 0.2
	check_enemy()
	check_timer.connect("timeout", self, "check_enemy")
	max_from_anchor_sqr = max_from_anchor * max_from_anchor

func hibernate():
	set_physics_process(false)
	set_process(false)
	check_timer.stop()
	movement = Vector2.ZERO

func angle_diff(a, b):
	return fmod(a - b + PI, PI*2) - PI

func target_condition(obj):
	return obj.is_inside_tree() and obj.side != 'junk' and (obj.global_position - anchored_position).length_squared() <= max_from_anchor_sqr

const max_rank = 2
func target_rank(obj):
	var turrets = obj.get('turrets')
	if turrets:
		var has_turret = false
		for turret in turrets:
			if not is_nan(turret.reload_time):
				has_turret = true
				break
		if has_turret:
			return 0
	return 1

var check_target_wait:float
const check_target_interval = 0.2
const focus_period = 0.1
var diff_norm:Vector2
var diff_length:float
var new_movement:Vector2
func _physics_process(delta):
	charge_bot_process(delta)
func charge_bot_process(delta):
	waited += delta
	if target_obj != null:
		if !target_condition(target_obj):
			remove_target()
		else:
			var target_accel = target_obj.linear_velocity - target_speed
			target_speed = target_obj.linear_velocity
			var parent_speed = parent.linear_velocity
			if current_firing_wait - waited < focus_period or check_target_wait > check_target_interval:
				target_check(target_accel)
			else:
				check_target_wait += delta
			if waited >= current_firing_wait and (target_speed - parent_speed).dot(diff_norm) < bullet_speed_approx: # only fire if our projectiles can actually close the distance to them
				var distance = max(diff_length - parent.size + target_obj.size, 0.00001) # modify the distance to decrease the turret angular precision in close range
				var acceptable_angle = asin(firing_angle * target_obj.size / sqrt(distance))
				if abs(angle_diff(angle, parent.rotation)) < acceptable_angle:
					emit_signal("start_firing") # finally, fire the turret
					current_firing_wait = firing_wait * log(distance / target_obj.size) / (1 + randf() * firing_wait_random)
					waited = 0
	else:
		new_movement = Vector2.ZERO
	movement = combine_movement(new_movement * parent.mass / 10) # combine with the movement from the base
	if new_movement.length_squared() < 0.0001:
		if anchored_position:
			movement += (anchored_position - parent.global_position - parent.linear_velocity)
		angle = movement.angle()

func target_check(target_accel):
	var parent_speed = parent.linear_velocity
	new_movement = Vector2.ZERO
	check_target_wait = 0
	var diff = target_obj.global_position - global_position
	diff -= diff.normalized() * parent.size # Approximate the distance from our turret to the target, which is more accurate
	diff = GameUtils.extrapolate(diff, target_speed, target_accel, bullet_speed_approx, parent_speed)
	diff_length = diff.length()
	diff_norm = diff / diff_length
	var movement_target = diff - diff_norm * distance_kept[target_rank] * parent.size
	new_movement = movement_target - parent_speed
	if new_movement.length() < thrust*10: # if we don't need to move much, randomly perform one of our idle action
		if strafe_direction != 0: # strafing to dodge projectiles
			new_movement += Vector2(-movement_target.y, movement_target.x).normalized() * strafe_force[target_rank] * strafe_direction
		else: # move toward the anchor
			var back = anchored_position - global_position
			if abs(diff_norm.dot(back.normalized())) < 0.8: # only do this if it doesn't change our distance to the target by much
				new_movement += back - parent.linear_velocity
			else:
				strafe_time = 0
	angle = GameUtils.moving_aim(parent_speed + new_movement*0.025 * turret_count, diff, bullet_speed_approx)

func check_enemy():
	var bodies = detector.get_overlapping_bodies()
	var min_dists = {}
	var chosen_bodies = {}
	for body in bodies:
		if body != parent and GameUtils.is_enemy(parent.side, body) and target_condition(body):
			var dist = (body.global_position - parent.global_position).length_squared()
			if body == target_obj:
				dist -= keep_target_preference / max(thrust, 1)
			var rank = target_rank(body)
			if rank in min_dists:
				var min_dist = min_dists[rank]
				if dist >= min_dist:
					continue
			min_dists[rank] = dist
			chosen_bodies[rank] = body
	for i in range(max_rank):
		target_obj = chosen_bodies.get(i)
		if target_obj:
			target_rank = i
			waited = 0
			current_firing_wait = 0
			target_speed = target_obj.linear_velocity
			break