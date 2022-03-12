extends Camera2D

export(Array, NodePath) var tracked_obj
var manual_adjustment:Vector2

func _ready():
	for i in range(len(tracked_obj)):
		tracked_obj[i] = get_node(tracked_obj[i])

func _process(delta):
	if tracked_obj:
		var center = Vector2.ZERO
		for obj in tracked_obj:
			center += obj.global_position
		global_position = center / len(tracked_obj)
