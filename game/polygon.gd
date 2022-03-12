extends Area2D

signal destroyed()

export var size:float = 1
onready var fill = $fill
var damage:float = 1

func init(size, point_count = 0):
	self.size = size
	var points = PoolVector2Array()
	if point_count == 0:
		point_count = round(8*sqrt(size))
	for i in range(point_count):
		points.push_back(Vector2(cos(i*2*PI/point_count), sin(i*2*PI/point_count)) * size)
	set_points(points)

func set_points(points):
	fill.polygon = points
	$collision.polygon = points

func destroyed():
	$anim.play("disappear")
	yield($anim, "animation_finished")
	emit_signal("destroyed")

func hibernate():
	$collision.disabled = true
	set_physics_process(false)
	set_process(false)
	visible = false
func wake_up():
	$collision.disabled = false
	set_physics_process(true)
	set_process(true)
	visible = true
	$anim.play("RESET")
