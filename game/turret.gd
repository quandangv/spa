extends Node2D

const turret_color = Color("FFFFFF")
const turret_hot_color = Color("FF4444")
const base_spread = 2
const base_fire_delay = 0.05
const turret_cooldown_base = 0.8
const plasma_density = 1
var plasma_pool = null
onready var controller = get_node("../controller")
onready var parent = get_parent()
onready var timer = $timer
onready var turret = $shape

var base_speed = 10
var reload_time:float = NAN
var plasma_hp:float = 12
var plasma_damage:float = 30
var fire_delay: float = 0
var plasma_mass: float

var turret_heat:float = 0
var turret_cooldown_speed:float
var fire_interval = 0

func _ready():
	controller.connect("start_firing", self, "start_firing")
	timer.connect("timeout", self, "_on_fire_timer")

func _process(delta):
	fire_interval += delta * turret_cooldown_speed
	turret.color = lerp(turret_hot_color, turret_color, clamp(fire_interval, 0, 4)/4)

func init(component):
	var size = 1
	var plasma_type = 'normal'
	var supply = component["_plasma_supply"]
	var power = component["_plasma_power"]
	var squeeze = component["_squeeze"]
	var position = component["position"]
	var spread = clamp(inverse_lerp(12, 0, supply), 0, 1)
	var points = PoolVector2Array()
	var base_width = size * lerp(1.5, 1, spread)
	var muzzle_width = size * lerp(1.5, 2, spread) if supply > 0 else 0.2
	var length = size * lerp(6, 2, spread)
	self.rotation = component["rotation"] * PI/3
	self.position = Vector2((parent.size * cos(PI/6) + length), (position-(squeeze-1)/2) * parent.size / squeeze*0.8).rotated(self.rotation)
	self.plasma_pool = get_node("/root/game/plasma_" + plasma_type)
	self.base_speed = 7 + power*2
	if supply:
		self.reload_time = 3.0/supply
		self.turret_cooldown_speed = supply
	else:
		self.reload_time = NAN
	self.plasma_hp = 2 * size
	self.plasma_damage = 6 + power * 3
	self.fire_delay = base_fire_delay * position
	self.plasma_mass = size * size * plasma_density
	points.push_back(Vector2(-length, base_width))
	points.push_back(Vector2(-length, -base_width))
	points.push_back(Vector2(0, -muzzle_width))
	points.push_back(Vector2(0, muzzle_width))
	turret.polygon = points
	turret.color = turret_color
	set_process(true)
	visible = true
	timer.stop()

func hibernate():
	set_process(false)
	reload_time = NAN
	visible = false

func _on_fire_timer():
	if abs(timer.wait_time - fire_delay) > 0.0001:
		if controller.firing:
			fire()
		else:
			timer.stop()

func fire():
	yield(get_tree().create_timer(fire_delay), "timeout")
	var turret_heat = pow(turret_cooldown_base, fire_interval)
	turret_heat += 1
	var buildup = clamp(1 / turret_heat, 0, 1)
	var velocity = (Vector2(base_speed, 0) * lerp(1, 8, buildup)).rotated(self.global_rotation\
			+ (randf()-0.5) * (1 - buildup) * base_spread) + parent.linear_velocity
	fire_interval = log(turret_heat)/log(turret_cooldown_base)
	parent.apply_central_impulse(-velocity * plasma_mass)
	plasma_pool.get_plasma(parent.side, plasma_hp, plasma_damage * buildup, self.global_position, velocity)
	$audio.play()

func start_firing():
	if timer.is_stopped() and not is_nan(reload_time):
		fire()
		timer.wait_time = reload_time
		timer.start()
