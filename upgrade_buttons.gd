extends Control

const megatypes = ["thruster", "turret", "radar"]
const supertypes = ["armor", "shield", "core"] + megatypes

onready var anim = get_node("anim")
onready var super = get_node("super")
onready var super_flip = get_node("super-flip")
onready var mega = get_node("mega")

func appear(type, show_super, show_super_flip, show_mega):
	disappear()
	if anim.is_playing():
		yield(anim, "animation_finished")
	anim.queue("appear")
	if type in supertypes:
		super.visible = show_super
		super.set_component("super" + type)
		super.disabled = false
		super_flip.visible = show_super_flip
		super_flip.set_component("super" + type)
		if type in megatypes:
			mega.visible = show_mega
			mega.set_component("mega" + type)
		else:
			mega.visible = false
	else:
		super.visible = false
		super_flip.visible = false
		mega.visible = false

func disappear():
	if visible:
		anim.play_backwards("appear")
