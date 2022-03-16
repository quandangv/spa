extends Node2D

signal start_firing
var movement:Vector2
var firing:bool
var angle:float
const stop_multiplier = 1
const thrust_to_rotate_speed = 3

onready var parent = get_parent()

func wake_up():
	if GameUtils.register_ship_input(self):
		gained_input()
	else:
		lost_input()

func hibernate():
	GameUtils.unregister_ship_input(self)
	lost_input()

func _input(_event):
	movement = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	firing = Input.is_action_pressed("fire")
	if Input.is_action_just_pressed("fire"):
		emit_signal("start_firing")
	angle = (self.get_global_mouse_position() - parent.global_position).angle()

func lost_input():
	set_process_input(false)
	movement = Vector2.ZERO

func gained_input():
	set_process_input(true)
	parent.set_color(GameUtils.side_colors["self"])
