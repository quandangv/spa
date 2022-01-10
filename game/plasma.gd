extends Area2D

export var size:float = 1
export var velocity:Vector2
export var hp:float = 1
export var damage:float = 1
export var collateral_damage:float = 0.1

func _ready():
	init(size, velocity)

func init(size, velocity):
	self.set_physics_process(true)
	self.size = size
	self.velocity = velocity
	var points = PoolVector2Array()
	var point_count = round(7*sqrt(size))
	print(point_count)
	for i in range(point_count):
		points.push_back(Vector2(cos(i*2*PI/point_count), sin(i*2*PI/point_count)) * size)
	$fill.set_points(points)
	$collision.polygon = points

func _physics_process(delta):
	position += velocity * delta
	var areas = get_overlapping_areas()
	for other in areas:
		if other.is_class(self.get_class()):
			self.hp -= other.damage
			if self.hp > 0:
				continue
		damage *= collateral_damage
		self.set_physics_process(false)
		$anim.play("disappear")
		break
