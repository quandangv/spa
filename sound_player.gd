extends Node

export(PackedScene) var player_pool_scene
export(Array, Resource) var sounds
export var base_attenuation:float = 2
export var base_player_count:int = 10
var sound_dict = {}

func _ready():
  for sound in sounds:
    var pool = player_pool_scene.instance()
    pool.size = int(ceil(base_player_count * sound.simultaneity))
    pool.name = sound.name
    add_child(pool)
    for player in pool.get_children():
      player.attenuation = sound.attenuation * base_attenuation
      player.bus = sound.bus
      player.stream = sound.sound
    sound_dict[sound.name] = [pool, sound]

func play_audio(name, position, pitch = null, volume_db = 0):
  var dict = sound_dict[name]
  var player = dict[0].get_object()
  if player == null:
    return
  player.global_position = position
  player.volume_db = dict[1].volume_db + volume_db
  player.pitch_scale = dict[1].pitch if pitch == null else pitch
  player.play()
  yield(player, "finished")
  dict[0]._recycle(player)
