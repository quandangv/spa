extends Node

export var battle_anim:NodePath
export var container_anim:NodePath
export var asteroids_path:NodePath
onready var boss = $boss
onready var asteroids = get_node(asteroids_path)
onready var parent = get_parent()

func _ready():
	remove_child(boss)

func enter_stage():
	SoundPlayer.play_audio("explosion", parent.global_position, 0.3, 10)
	asteroids.destroyed()
	get_node(battle_anim).play("battle")
	get_node(container_anim).play("destroyed")

func spawn_boss():
	add_child(boss)

func reset():
	if asteroids.target is RigidBody2D:
		var target = asteroids.target
		target.mode = RigidBody2D.MODE_KINEMATIC
		target.global_position = Vector2(-1500, 0)
		yield(get_tree(), "physics_frame")
		target.global_position = Vector2(-1500, 0)
		target.mode = RigidBody2D.MODE_RIGID
	if boss.is_inside_tree():
		boss.reset()


func end_game():
	$end_screen.global_position = boss.global_position
	$end_screen.wake_up()
