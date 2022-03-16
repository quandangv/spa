extends "polygon.gd"

const max_initial_torque = 10
const hp_multiplier = 0.25
const side = "junk"
var hp:float
var og_hp:float
var points:PoolVector2Array
var line_points:PoolVector2Array
export var color:Color
export var side_count:int = 5

func init_asteroid(size, mass, damage, color):
	self.size = size
	self.side_count = 6
	var step = PI*2 / side_count
	points.resize(side_count)
	line_points.resize(side_count+1)
	for i in range(side_count):
		points[i] = Vector2(size, 0).rotated(i * step)
		line_points[i] = points[i]
	collision.polygon = points
	line_points[side_count] = points[0]
	hp = mass * hp_multiplier
	set("mass", mass)
	self.og_hp = self.hp
	self.damage = damage
	self.color = color
	set("rotation", randf()*PI*2)
	set("angular_velocity", randf()*max_initial_torque / hp)
	$anim.play("RESET")

func _draw(): draw()
func draw():
	draw_colored_polygon(points, color)
	draw_polyline(line_points, Color.white, 1, true)

func area_interact(other):
	return hp > 0
func area_collide(other, delta):
	if hp > 0:
		hp -= other.damage * delta
		if hp <= 0:
			destroyed()
		else:
			update()
			color.a = lerp(0.2, 1, hp/og_hp)
			set("mass", hp / hp_multiplier)
	else:
		return 0
	return damage

func hibernate():
	collision.disabled = true
	set_physics_process(false)
func wake_up():
	collision.disabled = false
	set_physics_process(true)
