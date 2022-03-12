extends "polygon.gd"

const polygon_sizes = [3, 3, 5, 7]
const polygon_masses = [9, 12, 25, 50]
const polygon_damages = [15, 20, 25, 30]
const polygon_colors = [Color("#FF426B"), Color("#FFD806"), Color("#60A1FB"), Color("#60FBE8")]
const max_initial_force = 50
const max_initial_torque = 10
var side:String
var hp:float
var og_hp:float

func init_asteroid(side_count):
	var index = side_count - 3
	init(polygon_sizes[index], side_count)
	hp = polygon_sizes[index]
	set("mass", hp)
	self.og_hp = self.hp
	damage = polygon_damages[index]
	get_node("../fill").color = polygon_colors[index]
	set("rotation", randf()*PI*2)
	set("linear_velocity", Vector2(randf() * max_initial_force, 0).rotated(randf()*PI*2) / hp)
	set("angular_velocity", randf()*max_initial_torque / hp)

func set_points(points):
	.set_points(points)
	points.push_back(points[0])
	$outline.points = points

func area_collide(other, delta):
	hp -= other.damage * delta

func _physics_process(delta):
	if hp <= 0:
		damage = 0
		self.destroyed()
	else:
		fill.self_modulate = Color(1, 1, 1, hp/og_hp)

func hibernate():
	$collision.disabled = true
	set_physics_process(false)
func wake_up():
	$collision.disabled = false
	set_physics_process(true)
