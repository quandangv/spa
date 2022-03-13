extends Camera2D

export(Array, NodePath) var tracked_obj
var manual_adjustment:Vector2
var have_inputs:bool = true
const adjustment_speed = 100

func _ready():
	GameUtils.register_camera_input(self)
	for i in range(len(tracked_obj)):
		tracked_obj[i] = get_node(tracked_obj[i])

func lost_input():
	have_inputs = false
func gained_input():
	have_inputs = true

func _process(delta):
	if tracked_obj:
		var center = Vector2.ZERO
		for obj in tracked_obj:
			center += obj.global_position
		global_position = center / len(tracked_obj) + manual_adjustment
	if have_inputs:
		manual_adjustment += Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")) * delta * adjustment_speed
