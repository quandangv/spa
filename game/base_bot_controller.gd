extends Node2D

var movement_contribution:Vector2
const weight = 100

var tracked_projectiles = []
var tracked_bodies = []
onready var dodge_time = randf() * dodge_interval
const dodge_interval = 0.2
const max_tracked_projectiles = 9
const max_tracked_bodies = 17
const safe_distance_ratio = 3
const safe_body_distance_ratio = 2

onready var parent = get_parent()
onready var detector = $detector
export var detect_radius:float = 100
export var dodge_bodies:bool = true

func _ready():
  detector.connect("area_entered", self, "area_entered")
  detector.connect("area_exited", self, "area_exited")
  if dodge_bodies:
    detector.connect("body_entered", self, "body_entered")
    detector.connect("body_exited", self, "body_exited")
  detector.get_node("shape").shape.radius = detect_radius

func _physics_process(delta):
  dodge_time += delta
  if dodge_time > dodge_interval:
    update_movement()

func update_movement():
  dodge_time = 0
  movement_contribution = -GameUtils.dodge_projectiles(parent, safe_distance_ratio, tracked_projectiles, max_tracked_projectiles, 2)
  movement_contribution -= GameUtils.dodge_projectiles(parent, safe_body_distance_ratio, tracked_bodies, max_tracked_bodies, 6)

func combine_movement(movement):
  var result = movement + movement_contribution * weight
  return result

func area_entered(projectile):
  if GameUtils.is_enemy(parent.side, projectile):
    tracked_projectiles.push_back(projectile)
    dodge_time += dodge_interval/2

func body_entered(body):
  if not GameUtils.is_enemy(parent.side, body) and body != parent:
    tracked_bodies.push_back(body)
    dodge_time += dodge_interval/2

func area_exited(projectile):
  var index = tracked_projectiles.find(projectile)
  if index >= 0:
    tracked_projectiles.remove(index)

func body_exited(body):
  var index = tracked_bodies.find(body)
  if index >= 0:
    tracked_bodies.remove(index)
