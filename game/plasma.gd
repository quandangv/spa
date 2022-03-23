extends "polygon.gd"

const degradation_rate = 0.5
export var linear_velocity:Vector2
export var collateral_rate:float = 0.9
var lifetime:float
var hp:float
var og_hp:float
var side:String
var source
var color:Color
onready var fill = $fill

var overlap_bodies = []
var overlap_areas = []

func _ready():
  connect("area_entered", self, "area_entered")
  connect("area_exited", self, "area_exited")
  connect("body_entered", self, "body_entered")
  connect("body_exited", self, "body_exited")

func init_plasma(size, linear_velocity, hp):
  self.size = size
  $collision.shape.radius = size
  self.lifetime = 0
  self.linear_velocity = linear_velocity
  self.hp = hp
  self.og_hp = hp

func _physics_process(delta):
  position += linear_velocity * delta
  var damage_amount = 0
  for other in overlap_areas:
    damage_amount += other.damage
  for other in overlap_bodies:
    var other_damage = other.area_collide(self, delta)
    damage_amount += other_damage
  lifetime += delta
  damage_amount += lifetime * degradation_rate
  take_damage(damage_amount * delta)

puppetsync func master_destroyed(current_damage):
  damage = current_damage
  destroyed()
remote func take_damage(amount):
  if hp > 0:
    hp -= amount
    if hp <= 0:
      damage *= pow(collateral_rate, hp)
      if not GameUtils.networking:
        destroyed()
      elif is_network_master():
        rpc("master_destroyed", damage)
    else:
      color.a = lerp(0.2, 1, hp/og_hp)
      update()
  elif damage:
    damage *= pow(collateral_rate, -amount)

func area_entered(other):
  if GameUtils.is_enemy(side, other):
    SoundPlayer.play_audio("plasma_area", global_position)
    overlap_areas.push_back(other)
func area_exited(other):
  if other in overlap_areas:
    overlap_areas.erase(other)

func body_entered(other):
  if other.has_method("area_interact") and other.area_interact(self):
    overlap_bodies.push_back(other)
    if hp > 0:
      SoundPlayer.play_audio("plasma_body", global_position, hp/og_hp)
func body_exited(other):
  if other in overlap_bodies:
    overlap_bodies.erase(other)

func _draw():
  draw_circle(Vector2.ZERO, size, color)
