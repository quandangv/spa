extends "polygon.gd"

const degradation_rate = 0.5
export var linear_velocity:Vector2
export var collateral_rate:float = 0.75
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
  var damage = 0
  for other in overlap_areas:
    damage += other.damage
  for other in overlap_bodies:
    damage += other.area_collide(self, delta)
  if hp > 0:
    lifetime += delta
    damage += lifetime * degradation_rate
    hp -= damage*delta
    if hp <= 0:
      damage *= pow(collateral_rate, hp)
      destroyed()
    else:
      fill.self_modulate = Color(1, 1, 1, lerp(0.2, 1, hp/og_hp))
  elif damage:
    damage *= delta
    damage *= pow(collateral_rate, -damage)

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
