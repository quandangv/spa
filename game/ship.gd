extends RigidBody2D

signal destroyed

export(PackedScene) var thruster_scene
export(PackedScene) var turret_scene
export var starting_side:String = "player"
export var max_capture:int = 10
export var type:String = 'minimal_ship'
const border_damage_ratio = 4
const inner_damage = 4
const collision_threshold = 20
const collision_damage_multiplier = 0.03
const capture_distance = 10
const release_distance_sqr = 90000
var border_damage_accum = 0
var inner_damage_accum = 0
var size:float = 2
var turrets:Array = []
var damage = 10
var color = null
var real_mass: float
var og_mass:float
var side:String
var captured = []

var dhits = []
var hhits = []
var vhits = []
var map = []
var mapsize = 0

onready var shape = load("res://game/outlined_shape.tscn")
onready var controller = $controller

const ship_types = {
  'minimal_ship': '{"map":[null,{"":"thruster","hp":5,"rotation":0},{"":"core","hp":5,"rotation":0},{"":"generator","hp":5,"plasma_downstream":[[0,2]],"plasma_supply":6,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":6,"rotation":0},null],"mapsize":2}',
  'asteroid_breaker': '{"map":[null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,{"":"thruster","covered":[[2,0]],"hp":5,"rotation":0},{"":"turret","covered":[[2,0],[3,0]],"hp":5,"plasma_power":2,"plasma_supply":6,"position":1,"rotation":0},{"":"energizer","covered":[[3,0],[4,1]],"hp":5,"plasma_downstream":[[2,1]],"plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","hp":5,"rotation":0},{"":"energizer","hp":5,"plasma_downstream":[[2,1]],"plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":5,"plasma_downstream":[[1,2],[2,1],[3,1],[3,2],[2,3],[1,3]],"plasma_supply":12,"rotation":0},{"":"energizer","covered":[[3,3],[4,1]],"hp":5,"plasma_downstream":[[2,3]],"plasma_power":1,"plasma_supply":2,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"thruster","covered":[[3,3],[4,1]],"hp":5,"rotation":0},{"":"core","covered":[[0,4]],"hp":5,"rotation":0},{"":"turret","covered":[[0,4],[1,4]],"hp":5,"plasma_power":2,"plasma_supply":6,"position":0,"rotation":0},{"":"energizer","chained":true,"covered":[[1,4],[3,3]],"hp":5,"plasma_downstream":[[1,3]],"plasma_power":2,"plasma_supply":4,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null],"mapsize":5}',
  'asteroid_breaker2': '{"map":[null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","covered":[[2,0]],"hp":5,"rotation":0},{"":"thruster","covered":[[4,1]],"hp":5,"rotation":0},null,{"":"turret","covered":[[2,0]],"hp":5,"plasma_power":3,"plasma_supply":6,"position":0,"rotation":0},{"":"energizer","chained":true,"covered":[[2,0]],"hp":5,"plasma_downstream":[[1,1]],"plasma_power":3,"plasma_supply":6,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[4,1]],"hp":5,"plasma_downstream":[[2,1]],"plasma_power":2,"plasma_supply":4,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"core","hp":5,"rotation":0},{"":"energizer","hp":5,"plasma_downstream":[[1,3]],"plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":5,"plasma_downstream":[[1,2],[2,1],[3,1],[3,2],[2,3],[1,3]],"plasma_supply":12,"rotation":0},{"":"energizer","covered":[[3,3],[4,1],[4,2]],"hp":5,"plasma_downstream":[[3,1]],"plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"turret","covered":[[0,4]],"hp":5,"plasma_power":3,"plasma_supply":6,"position":1,"rotation":0},{"":"energizer","chained":true,"covered":[[0,4]],"hp":5,"plasma_downstream":[[0,3]],"plasma_power":3,"plasma_supply":6,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","covered":[[3,3]],"hp":5,"plasma_downstream":[[1,3]],"plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","covered":[[0,4]],"hp":5,"rotation":0},{"":"thruster","covered":[[3,3]],"hp":5,"rotation":0},null,null],"mapsize":5}',
  'energizer_chain_ship': '{"map":[null,null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,{"":"thruster","covered":[[0,2]],"hp":5,"rotation":0},{"":"energizer","chained":true,"covered":[[3,0]],"hp":5,"plasma_downstream":[[3,1]],"plasma_power":2,"plasma_supply":4,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[3,0],[4,1]],"hp":5,"plasma_downstream":[[3,2]],"plasma_power":3,"plasma_supply":6,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"energizer","covered":[[0,2]],"hp":5,"plasma_downstream":[[2,1]],"plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":5,"plasma_downstream":[[1,2],[2,1],[3,1],[3,2],[2,3],[1,3]],"plasma_supply":12,"rotation":0},{"":"energizer","chained":true,"covered":[[3,3],[4,1]],"hp":5,"plasma_downstream":[[2,3]],"plasma_power":4,"plasma_supply":8,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,{"":"core","covered":[[0,2]],"hp":5,"rotation":0},{"":"turret","covered":[[1,4]],"hp":5,"plasma_power":5,"plasma_supply":12,"rotation":0},{"":"energizer","chained":true,"covered":[[1,4],[3,3]],"hp":5,"plasma_downstream":[[1,3]],"plasma_power":5,"plasma_supply":10,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null],"mapsize":5}',
  'dodger_ship': '{"map":[null,null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"core","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","plasma_output":12,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"shield","rotation":0},null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,null],"mapsize":5}',
  'big_ship': '{"dhits":[[[0,2],[1,1],[2,0]],[[0,3],[1,2],[2,1],[3,0]],[[0,4],[1,3],[2,2],[3,1],[4,0]],[[1,4],[2,3],[3,2],[4,1]],[[2,4],[3,3],[4,2]]],"hhits":[[[2,0],[3,0],[4,0]],[[1,1],[2,1],[3,1],[4,1]],[[0,2],[1,2],[2,2],[3,2],[4,2]],[[0,3],[1,3],[2,3],[3,3]],[[0,4],[1,4],[2,4]]],"map":[null,null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"core","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","plasma_output":12,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"shield","rotation":0},null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,null],"mapsize":5,"stats":{"armor":0,"radar":0,"shield":1,"size":5,"thrust":4,"weight":19},"turrets":[[0,2],[0,4],[2,0],[2,4],[4,0],[4,2]],"vhits":[[[0,2],[0,3],[0,4]],[[1,1],[1,2],[1,3],[1,4]],[[2,0],[2,1],[2,2],[2,3],[2,4]],[[3,0],[3,1],[3,2],[3,3]],[[4,0],[4,1],[4,2]]]}',
  'defended_ship': '{"map":[null,null,{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"energizer","chained":true,"covered":[[2,0]],"hp":1,"plasma_power":3,"plasma_supply":6,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[5,0]],"hp":1,"plasma_power":2,"plasma_supply":4,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},null,{"":"collector","covered":[[0,2],[2,0]],"hp":1,"material_output":9,"rotation":0},{"":"energizer","chained":true,"covered":[[2,0]],"hp":1,"plasma_power":4,"plasma_supply":8,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":1,"plasma_output":12,"rotation":0},{"":"energizer","covered":[[5,0]],"hp":1,"plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"collector","covered":[[5,0],[5,2]],"hp":1,"material_output":9,"rotation":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"thruster","covered":[[0,2]],"hp":1,"rotation":0},{"":"energizer","chained":true,"hp":1,"plasma_power":5,"plasma_supply":10,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","hp":1,"plasma_power":10,"plasma_supply":24,"rotation":0},{"":"energizer","covered":[[5,2]],"hp":1,"plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"thruster","covered":[[0,2]],"hp":1,"rotation":0},{"":"core","hp":1,"rotation":0},{"":"energizer","chained":true,"hp":1,"plasma_power":5,"plasma_supply":10,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":1,"plasma_output":12,"rotation":0},{"":"energizer","chained":true,"covered":[[5,2]],"hp":1,"plasma_power":2,"plasma_supply":4,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,{"":"thruster","covered":[[0,5]],"hp":1,"rotation":0},{"":"thruster","covered":[[0,5]],"hp":1,"rotation":0},{"":"energizer","chained":true,"covered":[[2,5]],"hp":1,"plasma_power":4,"plasma_supply":8,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[2,5]],"hp":1,"plasma_power":3,"plasma_supply":6,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,null,{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"collector","covered":[[0,5],[2,5]],"hp":1,"material_output":9,"rotation":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},null,null,null],"mapsize":6}',
  'test_ship': '{"map":[null,{"":"thruster","hp":5,"rotation":0},{"":"turret","covered":[[2,1]],"hp":5,"plasma_power":0,"plasma_supply":4.5,"rotation":5},{"":"core","hp":5,"rotation":0},{"":"generator","covered":[[2,1]],"hp":5,"plasma_downstream":[[2,0],[1,2]],"plasma_supply":9,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","hp":5,"rotation":0},{"":"turret","covered":[[2,1]],"hp":5,"plasma_power":0,"plasma_supply":4.5,"rotation":0},null],"mapsize":3}',
  'play_ship': '{"map":[null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null,{"":"core","covered":[[2,0]],"hp":5,"rotation":0},{"":"turret","covered":[[2,0]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"turret","covered":[[4,1]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"generator","hp":5,"plasma_output":12,"rotation":0},{"":"turret","covered":[[3,3],[4,1]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},null,{"":"thruster","covered":[[0,4]],"hp":5,"rotation":0},{"":"turret","covered":[[0,4]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"turret","covered":[[3,3]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null,null],"mapsize":5}',
  'multi_dir_ship': '{"map":[null,{"":"core","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":2},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":1},null,{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":3},{"":"generator","hp":5,"plasma_downstream":[[1,1],[2,0],[3,0],[3,1],[2,2],[1,2]],"plasma_supply":12,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"thruster","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":4},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":5},null],"mapsize":4}',
}

func _ready():
  load_ship(parse_json(ship_types[type]))
  contact_monitor = true
  contacts_reported = 10
  connect("body_entered", self, "body_entered")

var last_velocity:Vector2
func _physics_process(_delta):
  last_velocity = linear_velocity
func body_entered(other):
  # Godot is inconsistent about when to emit this signal, the velocity of the other body may be before or after collision
  # So we just ignore the other body and track our velocity before and after collision
  var damage = (last_velocity - linear_velocity).length() - collision_threshold
  if damage > 0:
    damage *= mass * collision_damage_multiplier
    var damage_scale = clamp(inverse_lerp(1, 10, damage), 0, 1)
    SoundPlayer.play_audio("collision", global_position, lerp(2, 0.4, damage_scale), lerp(0, 10, damage_scale))
    for _i in range(100):
      damage -= take_damage((other.global_position - global_position).angle(), damage)
      if damage <= 0: break

func offer_capture(other):
  for i in range(len(captured)-1, -1, -1):
    if (captured[i].global_position - global_position).length_squared() > release_distance_sqr:
      captured[i].released()
      captured.remove(i)
  if len(captured) < max_capture:
    captured.append(other)
    return Vector2(capture_distance, 0).rotated(PI*2/max_capture * len(captured))
func demand_release(other):
  var index = captured.find(other)
  if index >= 0:
    captured.remove(index)
  return true

func load_ship(data):
  if not 'stats' in data:
    data = ComponentUtils.reanalyze_ship(data)
  var stats = data["stats"]
  self.hhits = data["hhits"]
  self.dhits = data["dhits"]
  self.vhits = data["vhits"]
  self.map = data["map"]
  self.mapsize = data["mapsize"]
  self.init(stats["size"])
  for i in range(len(hhits)):
    for j in range(len(hhits[i])):
      hhits[i][j] = get_map(hhits[i][j])
  for i in range(len(vhits)):
    for j in range(len(vhits[i])):
      vhits[i][j] = get_map(vhits[i][j])
  for i in range(len(dhits)):
    for j in range(len(dhits[i])):
      dhits[i][j] = get_map(dhits[i][j])
  var turret_pos = data["turrets"]
  for _i in range(len(turrets), len(turret_pos)):
    var ins = turret_scene.instance()
    add_child(ins)
    turrets.append(ins)
  for _i in range(len(turret_pos), len(turrets)):
    remove_child(turrets.pop_back())
  for component in map:
    if component != null and 'turret' in component['']:
      component['_squeeze'] = data['turret_rotations'][component['rotation']]
  reset()

func reset():
  $anim.play("RESET")
  self.color = null
  set_side(starting_side)
  controller.wake_up()
  var thrust = 0
  var turret_count = 0
  real_mass = 0
  for component in map:
    if component == null: continue
    component['_hp'] = component['hp']
    real_mass += 1
    if 'plasma_supply' in component:
      component['_plasma_supply'] = component['plasma_supply']
    if 'plasma_power' in component:
      component['_plasma_power'] = component['plasma_power']
    if 'turret' in component['']:
      var turret = turrets[turret_count]
      component['_ref'] = turret
      turret.init(component)
      turret_count += 1
    elif 'thruster' in component['']:
      thrust += 1
  mass = real_mass
  og_mass = real_mass
  color.a = 1
  if thrust > 0:
    if $thruster == null:
      var ins = thruster_scene.instance()
      add_child(ins)
      ins.name = "thruster"
    $thruster.init(thrust)
  elif $thruster != null:
    remove_child($thruster)
  for i in range(len(captured)-1, -1, -1):
    captured[i].released()
    captured.remove(i)
  if controller.has_method('on_turret_load'):
    controller.on_turret_load()

func get_map(pos):
  return self.map[pos[0] + pos[1] * mapsize]

func set_side(side):
  self.side = side
  if self.color == null:
    set_color(GameUtils.side_colors.get(side, Color.gray))

func set_color(color):
  self.color = color

func init(size):
  self.size = size
  $collision.shape.radius = size

func _draw():
  var point_count = round(8*sqrt(size))
  var fill_color = lerp(color, Color.white, inner_damage_accum)
  draw_circle(Vector2.ZERO, size, fill_color)
  draw_arc(Vector2.ZERO, size, 0, PI*2, point_count, lerp(Color.white, Color.red, border_damage_accum), 1, true)

func drop_plasma(component, supply_drop, power_drop):
  component['_plasma_supply'] -= supply_drop
  if power_drop > 0:
    component['_plasma_power'] -= power_drop
  if '_ref' in component:
    component['_ref'].init(component)
  if 'plasma_downstream' in component:
    var downstream = component['plasma_downstream']
    supply_drop /= len(downstream)
    power_drop /= len(downstream)
    for pos in downstream:
      var comp2 = get_map(pos)
      if comp2['_hp'] > 0:
        drop_plasma(comp2, supply_drop, power_drop)
func ship_destroyed():
  if side != "junk":
    self.color = null
    controller.hibernate()
    set_side('junk')
  if real_mass == 0:
    $anim.play("disappear")
    yield($anim, "animation_finished")
    emit_signal("destroyed")
func take_damage(angle, damage):
  var direction = (int(round((angle - rotation) / PI * 3)) + 6) % 6
  var component = null
  match direction:
    0:
      component = get_component(hhits[randi() % len(hhits)], -1)
    3:
      component = get_component(hhits[randi() % len(hhits)], 1)
    1:
      component = get_component(vhits[randi() % len(vhits)], -1)
    4:
      component = get_component(vhits[randi() % len(vhits)], 1)
    2:
      component = get_component(dhits[randi() % len(dhits)], 1)
    5:
      component = get_component(dhits[randi() % len(dhits)], -1)
  if component:
    if 'cover' in component:
      var cover = component['covered']
      cover.shuffle()
      for other in cover:
        other = get_map(other)
        if other['_hp'] > 0:
          component = other
          break
    component['_hp'] -= damage
    if component['_hp'] <= 0:
      SoundPlayer.play_audio("explosion", global_position)
      inner_damage_accum += inner_damage / size
      real_mass -= 1
      if 'plasma_downstream' in component:
        var supply_drop = component['_plasma_supply']
        var power_drop = component.get('_plasma_power', 0)
        drop_plasma(component, supply_drop, power_drop)
        if controller.has_method('on_turret_load'):
          controller.on_turret_load()
      match component['']:
        'thruster':
          $thruster.init($thruster.thrust - 1)
        'core':
          ship_destroyed()
        'turret':
          component['_ref'].hibernate()
      if real_mass <= 0:
        ship_destroyed()
      else:
        self.mass = real_mass
        color.a = lerp(0.2, 1, real_mass / og_mass)
      damage += component['_hp']
      component['_hp'] = 0
    border_damage_accum += border_damage_ratio * damage / size
    return damage
  return 0
func get_component(arr, index):
  for i in range(len(arr)) if index == 1 else range(-1, -len(arr)-1, -1):
    var component = arr[i]
    if component['_hp'] > 0:
      return component
  return null

func area_interact(other):
  return GameUtils.is_enemy(side, other)
func area_collide(other, delta):
  if GameUtils.is_enemy(side, other):
    var other_damage = other.damage*delta
    var damage_ratio = take_damage((-other.linear_velocity).angle(), other_damage) / other_damage
    return damage * damage_ratio
  return 0

func _process(delta):
  var update = false
  if border_damage_accum > 0:
    update = true
    border_damage_accum = max(border_damage_accum - delta, 0)
  if inner_damage_accum > 0:
    update = true
    inner_damage_accum = max(inner_damage_accum - delta, 0)
  if update:
    self.update()
