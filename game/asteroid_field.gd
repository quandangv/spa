extends Node2D

const spawn_rate = 1
export var spawn_range:Rect2
export(Array, int) var available_sizes
onready var pool = $pool

func _physics_process(delta):
	if randf() < spawn_rate * delta:
		var position = Vector2(randf()*spawn_range.size.x, randf()*spawn_range.size.y) + spawn_range.position
		var asteroid = pool.get_object()
		asteroid.position = position
		asteroid.side = "junk"
		asteroid.init_asteroid(available_sizes[randi() % len(available_sizes)])
