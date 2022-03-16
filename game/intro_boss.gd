extends Node

export var battle_anim:NodePath
export var container_anim:NodePath
export var asteroids_path:NodePath
export var lone_asteroid:NodePath
export var boss_music:AudioStream
export var boss_music_position:float
onready var boss = $boss
onready var asteroids = get_node(asteroids_path)
onready var parent = get_parent()

func _ready():
  remove_child(boss)

func enter_stage():
  SceneLoader.music.fade()
  SoundPlayer.play_audio("explosion", parent.global_position, 0.3, 10)
  asteroids.destroyed()
  get_node(battle_anim).play("battle")
  get_node(container_anim).play("destroyed")
  get_node(lone_asteroid).reset()

func spawn_boss():
  add_child(boss)
  SceneLoader.play_music(boss_music, boss_music_position)

func reset():
  if asteroids.target is RigidBody2D:
    var target = asteroids.target
    target.mode = RigidBody2D.MODE_KINEMATIC
    target.global_position = Vector2(-1500, 0)
    yield(get_tree(), "physics_frame")
    target.global_position = Vector2(-1500, 0)
    target.mode = RigidBody2D.MODE_RIGID
  if boss.is_inside_tree():
    boss.reset()

func end_game():
  SceneLoader.exp_circle_load("victory", boss.global_position)
