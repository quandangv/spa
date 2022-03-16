extends Polygon2D

var loader

func load_scene(path):
	loader = ResourceLoader.load_interactive(path)
	if loader == null:
		push_error("Can't load path: " + path)
		return
	set_process(true)
	$anim.play("end_screen")
func _process(delta):
	if loader == null:
		set_process(false)
		return
	var err = poll()
	if err == ERR_FILE_EOF:
		var resource = loader.get_resource()
		loader = null
		set_new_scene(resource)
	elif err != OK:
		push_error("Error while loading")
		loader = null
	else:
		var progress = float(loader.get_stage()) / (loader.get_stage_count()-1)
		var length = $anim.get_current_animation_length()
		$anim.seek(progress * length, true)
func poll():
	return loader.poll()
func set_new_scene(scene_resource):
	var root = get_node("/root")
	var old_scene = root.get_child(root.get_child_count() - 1)
	old_scene.name += "_old"
	old_scene.queue_free()
	root.add_child(scene_resource.instance())
