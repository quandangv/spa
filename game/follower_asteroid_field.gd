extends "asteroid_field.gd"

export var initial_velocity:Vector2
export var velocity_angle_range:float
export var attach_distance:Vector2
export(NodePath) var target
export(NodePath) var blue_container

func attach():
	target = get_node(target)
	blue_container = get_node(blue_container)
	get_parent().disconnect("screen_entered", self, "attach")
	wake_up()

func _ready():
	hibernate()

func _process(_delta):
	global_position = target.global_position + attach_distance

func init_asteroid(asteroid):
	.init_asteroid(asteroid)
	asteroid.linear_velocity = initial_velocity.rotated((randf()-0.5)*velocity_angle_range)
	if asteroid.color.r < 0.3 and asteroid.color.g > 0.5 and asteroid.color.b > 0.6:
		asteroid.following = true
		asteroid.secondary_target = target
		asteroid.primary_target = blue_container
	else:
		asteroid.following = false

func destroyed():
	set_process(false)
	for asteroid in $pool.get_children():
		asteroid.hp = 0
		asteroid.secondary_target = blue_container
		asteroid.destroyed()
	hibernate()
