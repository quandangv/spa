extends Node2D

export var size = 7
export var turret_color:Color
onready var shape = load("res://outlined_shape.tscn")

func _ready():
	set_size(size)
	add_turret(1, 1)
	add_turret(1, 0)
	add_turret(1, 0.5)
	add_turret(1, 1, 2)

func set_size(size):
	self.size = size
	var points = PoolVector2Array()
	points.push_back(Vector2(0, size))
	points.push_back(Vector2(cos(PI/6), 0.5) * size)
	points.push_back(Vector2(cos(PI/6), -0.5) * size)
	points.push_back(Vector2(0, -size))
	points.push_back(Vector2(-cos(PI/6), -0.5) * size)
	points.push_back(Vector2(-cos(PI/6), 0.5) * size)
	$hull.set_points(points)

func add_turret(size, spread, rotation = 0):
	var turret = shape.instance()
	var points = PoolVector2Array()
	var xoffset = -self.size * cos(PI/6)
	var base_width = size
	var muzzle_width = size * lerp(1, 3, spread)
	var length = size * lerp(6, 2, spread)
	points.push_back(Vector2(xoffset, base_width))
	points.push_back(Vector2(xoffset, -base_width))
	points.push_back(Vector2(xoffset - length, -muzzle_width))
	points.push_back(Vector2(xoffset - length, muzzle_width))
	turret.set_points(points)
	turret.color = turret_color
	turret.rotation = rotation * PI/3
	add_child(turret)
