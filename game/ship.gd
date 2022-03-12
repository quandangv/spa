extends RigidBody2D

export(PackedScene) var thruster_scene
export(PackedScene) var turret_scene
export var side = "player"
const border_damage_ratio = 2
const inner_damage = 4
var border_damage_accum = 0
var inner_damage_accum = 0
var size:float = 2
var turrets:Array = []
var damage = 10
var color = null
var real_mass: float

var dhits = []
var hhits = []
var vhits = []
var map = []
var mapsize = 0

onready var shape = load("res://game/outlined_shape.tscn")
onready var controller = $controller
onready var hull = $hull
onready var hull_outline = $hull/outline

func _ready():
	var _minimal_ship = '{"map":[null,{"":"thruster","hp":5,"rotation":0},{"":"core","hp":5,"rotation":0},{"":"generator","hp":5,"plasma_downstream":[[0,2]],"plasma_supply":6,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":6,"rotation":0},null],"mapsize":2}'
	var _basic_ship = '{"dhits":[[[0,1],[1,0]],[[1,1],[2,0]],[[2,1]]],"hhits":[[[1,0],[2,0]],[[0,1],[1,1],[2,1]],[]],"map":[null,{"":"core","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":4.5,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"thruster","rotation":0},{"":"generator","plasma_output":9,"rotation":0},{"":"turret","plasma_power":1,"plasma_supply":9,"rotation":0}],"mapsize":3,"stats":{"armor":0,"radar":0,"shield":0,"size":3,"thrust":1,"weight":5},"turrets":[[2,1]],"vhits":[[[0,1]],[[1,0],[1,1]],[[2,0],[2,1]]]}'
	var _energizer_chain_ship = '{"map":[null,null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,{"":"thruster","covered":[[0,2]],"hp":5,"rotation":0},{"":"energizer","chained":true,"covered":[[3,0]],"hp":5,"plasma_downstream":[[3,1]],"plasma_power":2,"plasma_supply":4,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[3,0],[4,1]],"hp":5,"plasma_downstream":[[3,2]],"plasma_power":3,"plasma_supply":6,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"energizer","covered":[[0,2]],"hp":5,"plasma_downstream":[[2,1]],"plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":5,"plasma_downstream":[[1,2],[2,1],[3,1],[3,2],[2,3],[1,3]],"plasma_supply":12,"rotation":0},{"":"energizer","chained":true,"covered":[[3,3],[4,1]],"hp":5,"plasma_downstream":[[2,3]],"plasma_power":4,"plasma_supply":8,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,{"":"core","covered":[[0,2]],"hp":5,"rotation":0},{"":"turret","covered":[[1,4]],"hp":5,"plasma_power":5,"plasma_supply":12,"rotation":0},{"":"energizer","chained":true,"covered":[[1,4],[3,3]],"hp":5,"plasma_downstream":[[1,3]],"plasma_power":5,"plasma_supply":10,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null],"mapsize":5}'
	var _dodger_ship = '{"map":[null,null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"core","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","plasma_output":12,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"shield","rotation":0},null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,null],"mapsize":5}'
	var _big_ship = '{"dhits":[[[0,2],[1,1],[2,0]],[[0,3],[1,2],[2,1],[3,0]],[[0,4],[1,3],[2,2],[3,1],[4,0]],[[1,4],[2,3],[3,2],[4,1]],[[2,4],[3,3],[4,2]]],"hhits":[[[2,0],[3,0],[4,0]],[[1,1],[2,1],[3,1],[4,1]],[[0,2],[1,2],[2,2],[3,2],[4,2]],[[0,3],[1,3],[2,3],[3,3]],[[0,4],[1,4],[2,4]]],"map":[null,null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"core","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","plasma_output":12,"rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"shield","rotation":0},null,{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},{"":"thruster","rotation":0},{"":"turret","plasma_power":1,"plasma_supply":2,"rotation":0},null,null],"mapsize":5,"stats":{"armor":0,"radar":0,"shield":1,"size":5,"thrust":4,"weight":19},"turrets":[[0,2],[0,4],[2,0],[2,4],[4,0],[4,2]],"vhits":[[[0,2],[0,3],[0,4]],[[1,1],[1,2],[1,3],[1,4]],[[2,0],[2,1],[2,2],[2,3],[2,4]],[[3,0],[3,1],[3,2],[3,3]],[[4,0],[4,1],[4,2]]]}'
	var _defended_ship = '{"map":[null,null,{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"energizer","chained":true,"covered":[[2,0]],"hp":1,"plasma_power":3,"plasma_supply":6,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[5,0]],"hp":1,"plasma_power":2,"plasma_supply":4,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},null,{"":"collector","covered":[[0,2],[2,0]],"hp":1,"material_output":9,"rotation":0},{"":"energizer","chained":true,"covered":[[2,0]],"hp":1,"plasma_power":4,"plasma_supply":8,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":1,"plasma_output":12,"rotation":0},{"":"energizer","covered":[[5,0]],"hp":1,"plasma_power":1,"plasma_supply":2,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"collector","covered":[[5,0],[5,2]],"hp":1,"material_output":9,"rotation":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"thruster","covered":[[0,2]],"hp":1,"rotation":0},{"":"energizer","chained":true,"hp":1,"plasma_power":5,"plasma_supply":10,"rotation":3,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"turret","hp":1,"plasma_power":10,"plasma_supply":24,"rotation":0},{"":"energizer","covered":[[5,2]],"hp":1,"plasma_power":1,"plasma_supply":2,"rotation":4,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"thruster","covered":[[0,2]],"hp":1,"rotation":0},{"":"core","hp":1,"rotation":0},{"":"energizer","chained":true,"hp":1,"plasma_power":5,"plasma_supply":10,"rotation":2,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"generator","hp":1,"plasma_output":12,"rotation":0},{"":"energizer","chained":true,"covered":[[5,2]],"hp":1,"plasma_power":2,"plasma_supply":4,"rotation":5,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,{"":"thruster","covered":[[0,5]],"hp":1,"rotation":0},{"":"thruster","covered":[[0,5]],"hp":1,"rotation":0},{"":"energizer","chained":true,"covered":[[2,5]],"hp":1,"plasma_power":4,"plasma_supply":8,"rotation":1,"wasted_plasma_power":0,"wasted_plasma_supply":0},{"":"energizer","chained":true,"covered":[[2,5]],"hp":1,"plasma_power":3,"plasma_supply":6,"rotation":0,"wasted_plasma_power":0,"wasted_plasma_supply":0},null,null,{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},{"":"collector","covered":[[0,5],[2,5]],"hp":1,"material_output":9,"rotation":0},{"":"armor","armor":1,"hp":2,"material_supply":4.5,"rotation":0},null,null,null],"mapsize":6}'
	var _test_ship = '{"map":[null,{"":"thruster","hp":5,"rotation":0},{"":"turret","covered":[[2,1]],"hp":5,"plasma_power":0,"plasma_supply":4.5,"rotation":5},{"":"core","hp":5,"rotation":0},{"":"generator","covered":[[2,1]],"hp":5,"plasma_downstream":[[2,0],[1,2]],"plasma_supply":9,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","hp":5,"rotation":0},{"":"turret","covered":[[2,1]],"hp":5,"plasma_power":0,"plasma_supply":4.5,"rotation":0},null],"mapsize":3}'
	var _play_ship = '{"map":[null,null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null,{"":"core","covered":[[2,0]],"hp":5,"rotation":0},{"":"turret","covered":[[2,0]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"turret","covered":[[4,1]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},{"":"thruster","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"generator","hp":5,"plasma_output":12,"rotation":0},{"":"turret","covered":[[3,3],[4,1]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},null,{"":"thruster","covered":[[0,4]],"hp":5,"rotation":0},{"":"turret","covered":[[0,4]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"turret","covered":[[3,3]],"hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,{"":"armor","armor":1,"hp":10,"material_supply":0,"rotation":0,"warning":"need_material_supply"},null,null,null,null],"mapsize":5}'
	var _multi_dir_ship = '{"map":[null,{"":"core","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":2},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":1},null,{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":3},{"":"generator","hp":5,"plasma_downstream":[[1,1],[2,0],[3,0],[3,1],[2,2],[1,2]],"plasma_supply":12,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":0},{"":"thruster","hp":5,"rotation":0},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":4},{"":"turret","hp":5,"plasma_power":0,"plasma_supply":2,"rotation":5},null],"mapsize":4}'
	load_ship(parse_json(_play_ship))
	set_side(side)

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
	if stats["thrust"] > 0:
		if $thruster == null:
			var ins = thruster_scene.instance()
			ins.name = "thruster"
			add_child(ins)
		$thruster.thrust = stats["thrust"]
	elif $thruster != null:
		remove_child($thruster)
	
	var turret_pos = data["turrets"]
	for _i in range(len(turrets), len(turret_pos)):
		var ins = turret_scene.instance()
		add_child(ins)
		turrets.append(ins)
	for _i in range(len(turret_pos), len(turrets)):
		remove_child(turrets.pop_back())
	var turret_count = 0
	for component in map:
		if component == null: continue
		if 'plasma_supply' in component:
			component['_plasma_supply'] = component['plasma_supply']
		if 'plasma_power' in component:
			component['_plasma_power'] = component['plasma_power']
		if 'turret' in component['']:
			var turret = turrets[turret_count]
			var size = 1
			component['_ref'] = turret
#			turret['rotation'] = int(turret['rotation'])
			component['_squeeze'] = data['turret_rotations'][component['rotation']]
			turret.init(component)
			turret_count += 1
	real_mass = 0
	for component in map:
		if component:
			component['_hp'] = component['hp']
			real_mass += 1
	mass = real_mass
	for i in range(len(hhits)):
		for j in range(len(hhits[i])):
			hhits[i][j] = get_map(hhits[i][j])
	for i in range(len(vhits)):
		for j in range(len(vhits[i])):
			vhits[i][j] = get_map(vhits[i][j])
	for i in range(len(dhits)):
		for j in range(len(dhits[i])):
			dhits[i][j] = get_map(dhits[i][j])
	if controller.has_method('on_turret_load'):
		controller.on_turret_load()

func get_map(pos):
	return self.map[pos[0] + pos[1] * mapsize]

func set_side(side):
	self.side = side
	if self.color == null:
		set_color(GameUtils.side_colors.get(side, Color.gray))

func set_color(color):
	$hull.color = color
	self.color = color

func init(size):
	self.size = size
	var points = PoolVector2Array()
	points.push_back(Vector2(0, size))
	points.push_back(Vector2(cos(PI/6), 0.5) * size)
	points.push_back(Vector2(cos(PI/6), -0.5) * size)
	points.push_back(Vector2(0, -size))
	points.push_back(Vector2(-cos(PI/6), -0.5) * size)
	points.push_back(Vector2(-cos(PI/6), 0.5) * size)
	$hull.set_points(points)
	$collision.polygon = points

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
	self.color = null
	controller.hibernate()
	set_side('junk')
	if real_mass == 0:
		$anim.play("disappear")
func take_damage(component, damage):
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
		$explosion.play()
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
				$thruster.thrust -= 1
			'core':
				ship_destroyed()
			'turret':
				component['_ref'].hibernate()
		if real_mass <= 0:
			ship_destroyed()
		else:
			self.mass = real_mass
	border_damage_accum += border_damage_ratio * damage / size
func get_component(arr, index):
	for i in range(len(arr)) if index == 1 else range(-1, -len(arr), -1):
		var component = arr[i]
		if component['_hp'] > 0:
			return component
	return null
func area_collide(other, delta):
	if GameUtils.is_enemy(side, other):
		var direction = (int(round(((-other.linear_velocity).angle() - rotation) / PI * 3)) + 6) % 6
		var component = null
		match direction:
			0:
				component = get_component(hhits[randi() % len(hhits)], -1)
			3:
				component = get_component(hhits[randi() % len(hhits)], 1)
			1:
				component = get_component(vhits[randi() % len(dhits)], -1)
			4:
				component = get_component(vhits[randi() % len(dhits)], 1)
			2:
				component = get_component(dhits[randi() % len(dhits)], 1)
			5:
				component = get_component(dhits[randi() % len(dhits)], -1)
		if component:
			take_damage(component, other.damage*delta)

func _process(delta):
	if border_damage_accum > 0:
		border_damage_accum = max(border_damage_accum - delta, 0)
		hull_outline.modulate = lerp(Color.white, Color.red, border_damage_accum)
	if inner_damage_accum > 0:
		inner_damage_accum = max(inner_damage_accum - delta, 0)
		hull.color = lerp(color, Color.white, inner_damage_accum)
