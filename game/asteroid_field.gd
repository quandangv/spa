extends Node2D

export var spawn_rate:float = 0.25
export var spawn_range:Rect2
export var available_sizes_range:Vector2
export var colors:Gradient
export var autostart:bool = true
onready var pool = $pool

func _process(delta):
	if randf() < spawn_rate * delta:
		var asteroid = pool.get_object()
		init_asteroid(asteroid)

func _ready():
	if not autostart:
		hibernate()

func hibernate():
	set_process(false)
func wake_up():
	set_process(true)

func init_asteroid(asteroid):
	asteroid.wake_up()
	var position = Vector2(randf()*spawn_range.size.x, randf()*spawn_range.size.y) + spawn_range.position + global_position
	asteroid.global_position = position
	asteroid.anim.play('RESET')
	var size = lerp(available_sizes_range.x, available_sizes_range.y, randf())
	asteroid.init_asteroid(size, size * size, 20, colors.interpolate(randf()))
