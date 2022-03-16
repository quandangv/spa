extends "res://game/following_asteroid.gd"

var og_position:Vector2
var og_mass:float
var resetting:bool = false
export var primary_target_path:NodePath
export var secondary_target_path:NodePath

func _ready():
	og_position = global_position
	og_mass = get('mass')
	following = true
	primary_target = get_node(primary_target_path)
	secondary_target = get_node(secondary_target_path)
	if size > 0:
		reset()

func _integrate_forces(state):
	if resetting:
		state.transform = Transform2D(0.0, og_position)
		state.linear_velocity = Vector2.ZERO
		resetting = false

func reset():
	resetting = true
	destroyed_once = false
	$collision.disabled = false
	init_asteroid(size, og_mass, damage, color)
	update()
