extends Node

export(Array, Resource) var sounds
var sound_dict = {}
onready var players = $pool

func _ready():
  for s in sounds:
    sound_dict[s.name] = s

func play_audio(name, position, pitch = null, volume_db = 0):
  var player = players.get_object()
  player.global_position = position
  var sound = sound_dict[name]
  player.volume_db = sound.volume_db + volume_db
  player.pitch_scale = sound.pitch if pitch == null else pitch
  player.attenuation = sound.attenuation
  player.bus = sound.bus
  player.stream = sound.sound
  player.play()
  yield(player, "finished")
  players._recycle(player)
