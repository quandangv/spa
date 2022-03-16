extends VisibilityNotifier2D

export var grace_period:float
var wait:float

func _enter_tree():
	wait = 0

func _process(delta):
	if not is_on_screen():
		wait += delta
		if wait > grace_period:
			get_parent().destroyed()
	else:
		wait = 0
