extends Area2D

signal destroyed()

export var size:float = 1
onready var fill = $fill
var damage:float = 1
var color:Color

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
