extends Node

export var battle_anim:NodePath
export var container_anim:NodePath
export var asteroids_path:NodePath
export(NodePath) var lone_asteroid
export var boss_music:AudioStream
export var boss_music_position:float
export var reset_position:Vector2 = Vector2(-1430, 0)
onready var boss = $boss
onready var asteroids = get_node(asteroids_path)
onready var parent = get_parent()

func _ready():
  remove_child(boss)
  lone_asteroid = get_node(lone_asteroid)

func enter_stage():
  get_node("/root/game/camera").shake += Vector2(100, 0)
  asteroids.stage_name.text = "dogfight"
  SceneManager.music.fade()
  SoundPlayer.play_audio("explosion", parent.global_position, 0.3, 10)
  asteroids.destroyed()
  get_node(battle_anim).play("battle")
  get_node(container_anim).play("destroyed")
  lone_asteroid.reset()

func spawn_boss():
  add_child(boss)
  SceneManager.play_music(boss_music, boss_music_position)

func reset():
  if asteroids.target is RigidBody2D:
    var target = asteroids.target
    target.mode = RigidBody2D.MODE_KINEMATIC
    target.global_position = reset_position
    yield(get_tree(), "physics_frame")
    target.global_position = reset_position
    target.mode = RigidBody2D.MODE_RIGID
  if boss.is_inside_tree():
    boss.reset()

func end_game():
  Storage.give_rank("ensign")
  Storage.save()
  var pos = boss.get_global_transform_with_canvas().origin
  var without_asteroid = (lone_asteroid.global_position - lone_asteroid.og_position).length_squared() < 0.001
  SceneManager.exp_circle_load("victory", pos, Color.yellow if without_asteroid else Color.white)
