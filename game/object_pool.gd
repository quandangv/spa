extends Node

signal created(instance)
export(PackedScene) var scene
var pool = []

func _create():
	var instance = scene.instance()
	instance.connect("destroyed", self, "_recycle", [instance])
	add_child(instance)
	emit_signal("created", instance)
	return instance

func _recycle(instance):
	if !instance.has_meta("recycled"):
		instance.hibernate()
		instance.set_meta("recycled", true)
		pool.append(instance)

func get_object():
	var object = _create() if len(pool) == 0 else pool.pop_back()
	object.remove_meta("recycled")
	object.wake_up()
	return object
