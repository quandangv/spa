extends Node2D

var movement_contribution:Vector2
const weight = 100

var tracked_projectiles = []
var safe_distance_sqr:float
onready var dodge_time = randf() * dodge_interval
const dodge_interval = 0.2
const max_tracked_projectiles = 10
const base_safe_distance = 3

onready var parent = get_parent()
onready var detector = $detector
export var detect_radius:float = 100

func _ready():
  detector.connect("area_entered", self, "area_entered")
  detector.connect("area_exited", self, "area_exited")
  detector.get_node("shape").shape.radius = detect_radius
  safe_distance_sqr = parent.size * base_safe_distance
  safe_distance_sqr *= safe_distance_sqr

func _physics_process(delta):
  dodge_time += delta
  if dodge_time > dodge_interval:
    update_movement()

func update_movement():
  dodge_time = 0
  movement_contribution = -GameUtils.dodge_projectiles(parent.global_position, parent.linear_velocity, safe_distance_sqr, tracked_projectiles, max_tracked_projectiles)

func combine_movement(movement):
  var result = movement + movement_contribution * weight
  return result

func area_entered(projectile):
  if GameUtils.is_enemy(parent.side, projectile):
    tracked_projectiles.push_back(projectile)
    dodge_time += dodge_interval/2

func area_exited(projectile):
  if projectile in tracked_projectiles:
    tracked_projectiles.erase(projectile)
