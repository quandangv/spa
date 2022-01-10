extends Control

const megatypes = ["thruster", "turret", "radar"]
const supertypes = ["armor", "shield", "core"] + megatypes

onready var anim = get_node("anim")
onready var super:Button = get_node("super")
onready var super_flip = get_node("super-flip")
onready var mega = get_node("mega")
onready var help = get_node("help")
var type

func _ready():
	super.connect("mouse_exited", self, "set_help", [""])
	super_flip.connect("mouse_exited", self, "set_help", [""])
	mega.connect("mouse_exited", self, "set_help", [""])
	super.connect("mouse_entered", self, "set_help", ["super"])
	super_flip.connect("mouse_entered", self, "set_help", ["super"])
	mega.connect("mouse_entered", self, "set_help", ["mega"])

func set_help(prefix):
	help.bbcode_text = "[b]" + tr(prefix + type).to_upper() + "[/b] " + tr(prefix + type + "_help")

func appear(type, show_super, show_super_flip, show_mega):
	disappear()
	if anim.is_playing():
		yield(anim, "animation_finished")
	self.type = type
	set_help("")
	anim.queue("appear")
	if type in supertypes:
		super.visible = true
		super.disabled = not show_super
		super.set_component("super" + type)
		super_flip.visible = true
		super_flip.disabled = not show_super_flip
		super_flip.set_component("super" + type)
		if type in megatypes:
			mega.visible = true
			mega.disabled = not show_mega
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
