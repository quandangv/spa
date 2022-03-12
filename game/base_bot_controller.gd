extends Node2D

var movement_contribution:Vector2
const weight = 100

var anchored_position = null
const to_target_weight = 0.2

var tracked_projectiles = []
var safe_distance_sqr:float
onready var dodge_time = randf() * dodge_interval
const dodge_interval = 0.2
const max_tracked_projectiles = 10
const base_safe_distance = 3

var strafe_time:float
var strafe_direction = 1
const strafe_max = 3

onready var parent = get_parent()
onready var detector = $enemy_detect

func _ready():
	detector.connect("area_entered", self, "area_entered")
	detector.connect("area_exited", self, "area_exited")
	safe_distance_sqr = parent.size * base_safe_distance
	safe_distance_sqr *= safe_distance_sqr
	anchored_position = parent.global_position

func _physics_process(delta):
	strafe_time -= delta
	if strafe_time <= 0:
		strafe_time = randf() * strafe_max
		strafe_direction = randi() % 3 - 1
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
