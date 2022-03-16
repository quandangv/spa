extends Node


export(Array, Resource) var scenes
var scene_dict = {}
var fade_animation:Animation
var fade_modulate_track:int
var loading:bool = false
onready var anim = $anim
onready var music = $music
onready var queue = $queue


func _ready():
  fade_animation = $anim.get_animation("fade")
  fade_modulate_track = fade_animation.find_track("rect:modulate")
  for scene in scenes:
    scene_dict[scene.name] = scene


func exp_circle_load(to_scene, starting_position):
  if not loading:
#    $rect.rect_global_position = starting_position
    to_scene = scene_dict[to_scene]
    _load_scene(to_scene.path, "exp_circle", to_scene.music)


func fade_load(from_scene, to_scene):
  if not loading:
    from_scene = scene_dict[from_scene]
    to_scene = scene_dict[to_scene]
    customize_fade(from_scene.color, to_scene.color)
    _load_scene(to_scene.path, "fade", to_scene.music)


func customize_fade(start_color, end_color):
  var mid_color = (start_color + end_color)/2
  mid_color.a = 1
  start_color.a = 0
  end_color.a = 0
  fade_animation.track_set_key_value(fade_modulate_track, 0, start_color)
  fade_animation.track_set_key_value(fade_modulate_track, 1, mid_color)
  fade_animation.track_set_key_value(fade_modulate_track, 2, mid_color)
  fade_animation.track_set_key_value(fade_modulate_track, 3, end_color)


func _load_scene(path, animation, stream):
  loading = true
  queue.queue_resource(path, true)
  anim.play(animation)
  if stream != null:
    music.fade()
  var tree = get_tree()
  var half_length = anim.get_current_animation_length()/2
  
  anim.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL
  while anim.current_animation_position < half_length:
    yield(tree, "idle_frame")
    anim.advance(get_process_delta_time())
  
  var resource = queue.get_resource(path)
  var root = get_node("/root")
  var old_scene = root.get_child(root.get_child_count() - 1)
  old_scene.name += "_old"
  root.add_child(resource.instance())
  old_scene.visible = false
  old_scene.queue_free()
  anim.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE
  if stream != null:
    yield(anim, "animation_finished")
    play_music(stream)
  
  loading = false


func play_scene_music(name):
  play_music(scene_dict[name].music)

func play_music(stream, position = 0):
  music.stream = stream
  music.restore(-10)
  music.play(position)
