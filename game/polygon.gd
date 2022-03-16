extends CollisionObject2D

signal destroyed()

export var size:float = 0
export var damage:float = 1
onready var collision = $collision
onready var anim = $anim

func destroyed():
  anim.play("disappear")
  yield(anim, "animation_finished")
  emit_signal("destroyed")
