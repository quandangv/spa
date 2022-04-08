extends Node2D

const turret_color = Color("FFFFFF")
const turret_hot_color = Color("FF4444")
const base_spread = 2
const base_fire_delay = 0.05
const turret_cooldown_base = 0.8
onready var controller = get_node("../controller")
onready var parent = get_parent()
onready var timer = $timer
onready var turret = $shape
var plasma_pool = null

var base_speed = 10
var reload_time:float = NAN
var plasma_hp:float = 12
var plasma_damage:float = 30
var fire_delay: float = 0
var turret_cooldown_speed:float
var wait_before_fire:float = -1

var turret_heat:float = 0
var fire_interval = 0
var queued_shots = 0
const max_queued_time = 0.5
var max_queued_shots:int
var plasma_mask
var plasma_layer

func _ready():
  if controller:
    controller.connect("start_firing", self, "start_firing")
  timer.connect("timeout", self, "_on_fire_timer")

func _process(delta):
  fire_interval += delta * turret_cooldown_speed
  turret.color = lerp(turret_hot_color, turret_color, clamp(fire_interval, 0, 4)/4)
  if wait_before_fire >= 0:
    if wait_before_fire < fire_delay:
      wait_before_fire += delta
    else:
      if Multiplayer.active:
        if is_network_master():
          rpc("_fire", "plasma" + String(Multiplayer.get_unique_id()))
      else:
        _fire()
      wait_before_fire = -1

func init(component):
  var size = 1
  var plasma_type = 'normal'
  var supply = component["_plasma_supply"]
  var power = component["_plasma_power"]
  var squeeze = component["_squeeze"]
  var position = component["position"]
  var spread = clamp(inverse_lerp(24, 0, supply), 0, 1)
  var base_width = size * lerp(3, 1, spread)
  var muzzle_width = size * lerp(4, 1, spread) if supply > 0 else 0.2
  var length = size * lerp(8, 2, spread)
  self.rotation = component["rotation"] * PI/3
  self.position = Vector2((parent.size * cos(PI/6) + length), (position-(squeeze-1)/2.0) * parent.size / squeeze*0.8).rotated(self.rotation)
  self.plasma_pool = get_node("/root/game/plasma_" + plasma_type)
  self.base_speed = 5 + power * 2.5
  if supply:
    self.reload_time = 3.0/supply
    self.turret_cooldown_speed = supply
    self.max_queued_shots = round(max_queued_time / reload_time)
  else:
    self.reload_time = NAN
  self.plasma_hp = 1.5 * size
  self.plasma_damage = 10 + power * 5
  self.fire_delay = base_fire_delay * position
  self.plasma_mask = GameUtils.get_plasma_mask(parent.side_layer)
  self.plasma_layer = GameUtils.get_plasma_layer(parent.side_layer)
  var points = PoolVector2Array()
  points.push_back(Vector2(-length, base_width))
  points.push_back(Vector2(-length, -base_width))
  points.push_back(Vector2(0, -muzzle_width))
  points.push_back(Vector2(0, muzzle_width))
  turret.polygon = points
  turret.color = turret_color
  set_process(true)
  visible = true
  timer.wait_time = reload_time
  timer.stop()

func hibernate():
  set_process(false)
  reload_time = NAN
  visible = false

func _on_fire_timer():
  if abs(timer.wait_time - fire_delay) > 0.0001:
    if not controller.firing:
      if queued_shots <= 0:
        timer.stop()
        return
      else:
        queued_shots -= 1
    wait_before_fire = 0

puppetsync func _fire(plasma_name = null):
  var turret_heat = pow(turret_cooldown_base, fire_interval)
  turret_heat += 1
  var buildup = clamp(1 / turret_heat, 0, 1)
  var velocity = (Vector2(base_speed, 0) * lerp(1, 10, buildup)).rotated(self.global_rotation\
      + (randf()-0.5) * (1 - buildup) * base_spread) + parent.linear_velocity
  fire_interval = log(turret_heat)/log(turret_cooldown_base)
  $audio.play()
  var plasma = plasma_pool.get_plasma(parent, plasma_hp, plasma_damage * buildup, self.global_position, velocity)
  plasma.collision_mask = plasma_mask
  plasma.collision_layer = plasma_layer
  if plasma_name != null:
    plasma.name = plasma_name

func start_firing():
  if not is_nan(reload_time):
    if timer.is_stopped():
      wait_before_fire = 0
      timer.start()
      queued_shots = 0
    elif queued_shots < max_queued_shots:
      queued_shots += 1
