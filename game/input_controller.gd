extends Node2D

signal start_firing
var movement:Vector2
var firing:bool
var angle:float
var stop_multiplier:float
const thrust_to_rotate_speed = 3

onready var parent = get_parent()

func _ready():
	parent.set_color(GameUtils.side_colors["self"])
func _input(event):
	movement = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	firing = Input.is_action_pressed("fire")
	if Input.is_action_just_pressed("fire"):
		emit_signal("start_firing")
	angle = (self.get_global_mouse_position() - parent.global_position).angle()
	stop_multiplier = 0 if Input.is_action_pressed("keep_speed") else 0.5
func hibernate():
	set_process_input(false)
	movement = Vector2.ZERO
	stop_multiplier = 1
