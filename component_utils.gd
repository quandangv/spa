extends Node

const super_coords = [Vector2(-1, 1), Vector2(0, 1)]
const super_flip_coords = [Vector2(0, -1), Vector2(1, -1)]
const mega_extra_coords = [Vector2(-1, 0), Vector2(1, 0)]
const mega_coords = [Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)]

const component_hp = {"armor":2}
const base_component_hp = 5

export var tileset: TileSet
export var tile_radius: float
export var tilset_cell_size: float
export(Dictionary) var stat_color
onready var tile_transform = Transform2D(Vector2(tile_radius * sin(PI/3) *2, 0),
	Vector2(tile_radius * sin(PI/3), tile_radius*1.5), Vector2.ZERO)
onready var tile_inverse_trans = tile_transform.affine_inverse()

func local_to_map(pos):
	pos = tile_inverse_trans * pos
	return pos.round()

func map_to_local(pos):
	return tile_transform * pos

func _ready():
	for id in tileset.get_tiles_ids():
		var name = tileset.tile_get_name(id)
		var offset = Vector2.ZERO
		if "thruster" in name or "turret" in name:
			if "super" in name or "mega" in name:
				if "top" in name:
					if "rotate" in name:
						offset.x += tilset_cell_size/4
						offset.y -= tilset_cell_size/2
					else:
						offset.x += tilset_cell_size/2
			elif "top" in name:
				offset.y -= tilset_cell_size/4
		if "super" in name:
			var flip_id = 1000 + id
			tileset.create_tile(flip_id)
			tileset.tile_set_name(flip_id, name + "-flip")
			tileset.tile_set_z_index(flip_id, tileset.tile_get_z_index(id))
			tileset.tile_set_texture(flip_id, tileset.tile_get_texture(id))
			tileset.tile_set_region(flip_id, tileset.tile_get_region(id))
			tileset.tile_set_texture_offset(flip_id, offset + Vector2.UP*tile_radius * (-1 if "base" in name else 1))
			offset.y += tile_radius
		tileset.tile_set_texture_offset(id, offset)

const normal_neighbors = mega_coords
const super_neighbors = [Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0),
	Vector2(1, 0), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 2), Vector2(-2, 2), Vector2(-2, 1)]
const super_flip_neighbors = [Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0),
	Vector2(1, 0), Vector2(-1, -1), Vector2(0, -2), Vector2(1, -2), Vector2(2, -2), Vector2(2, -1)]
const mega_neighbors = [Vector2(0, -2), Vector2(1, -2), Vector2(2, -2),
	Vector2(2, -1), Vector2(2, 0), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 2), Vector2(-2, 2),
	Vector2(-2, 1), Vector2(-2, 0), Vector2(-1, 1)]

func add_dict(dict, key, amount = 1):
	if key in dict:
		dict[key] += amount
	else:
		dict[key] = amount

func get2D(array, size, pos):
	return array[pos.x + pos.y*size]

func update_range(r, value):
	if value < r[0]:
		r[0] = value
	if value + 1 > r[1]:
		r[1] = value + 1

const output_by_side = [0, 6.0, 9.0, 11.0, 11.0, 11.0, 12.0]
func analyze_components(tiles, size):
	var stats = {"thrust":0, "radar":0, "armor": 0, "shield":0}
	var generators = {}
	var energizers = {}
	var turrets = {}
	var armors = {}
	var collectors = {}
	var assemblers = {}
	var hrange = [size, 0]
	var vrange = [size, 0]
	var drange = [size*2, 0]
	var vsize = len(tiles) / size
	for x in range(size):
		for y in range(vsize):
			var tile = tiles[x + y*size]
			if tile == null or "destroyed" in tile: continue
			update_range(hrange, x)
			update_range(vrange, y)
			update_range(drange, x + y)
			tile.erase("covered")
			tile.erase("warning")
			var pos = Vector2(x, y)
			tile["hp"] = component_hp.get(tile[""], 1) * base_component_hp
			match tile[""]:
				"generator":
					generators[pos] = tile
				"energizer":
					tile.erase("chained")
					tile.erase("next")
					tile["plasma_supply"] = 0
					tile["plasma_power"] = 1
					energizers[pos] = tile
				"turret":
					tile["plasma_supply"] = 0
					tile["plasma_power"] = 0
					turrets[pos] = tile
				"superturret":
					tile["plasma_supply"] = 0
					tile["plasma_power"] = 0
					turrets[pos] = tile
					if "flip" in tile and tile["flip"]:
						for delta in super_flip_coords:
							turrets[pos + delta] = tile
					else:
						for delta in super_coords:
							turrets[pos + delta] = tile
				"megaturret":
					tile["plasma_supply"] = 0
					tile["plasma_power"] = 0
					for delta in mega_coords:
						turrets[pos + delta] = tile
				"thruster":
					stats["thrust"] += 1
				"superthruster":
					stats["thrust"] += 3
					add_dict(stats, "force")
					tile["force"] = true
				"megathruster":
					stats["thrust"] += 7
					add_dict(stats, "boost")
					tile["boost"] = true
				"radar":
					stats["radar"] += 1
				"superradar":
					stats["radar"] += 3
					add_dict(stats, "focus")
					tile["focus"] = true
				"megaradar":
					stats["radar"] += 7
					add_dict(stats, "map_detail")
					tile["map_detail"] = true
				"armor":
					tile["armor"] = 1
					tile["material_supply"] = 0
					armors[pos] = tile
				"superarmor":
					tile["armor"] = 3
					tile["material_supply"] = 0
					armors[pos] = tile
					if "flip" in tile and tile["flip"]:
						for delta in super_flip_coords:
							armors[pos + delta] = tile
					else:
						for delta in super_coords:
							armors[pos + delta] = tile
				"shield":
					stats["shield"] += 1
				"supershield":
					stats["shield"] += 3
					add_dict(stats, "absorb")
					tile["absorb"] = true
				"supercore":
					add_dict(stats, "multitask")
					tile["multitask"] = true
				"assembler":
					tile["material_supply"] = 0
					assemblers[pos] = tile
				"collector":
					collectors[pos] = tile
	stats["size"] = max(0, max(hrange[1] - hrange[0], max(vrange[1] - vrange[0], drange[1] - drange[0])))
	stats["hrange"] = hrange
	stats["vrange"] = vrange
	stats["drange"] = drange
	for pos in generators:
		var tile = generators[pos]
		var connections = []
		var downstream = []
		for delta in mega_coords:
			var pos2 = delta + pos
			if pos2 in turrets:
				connections.append(turrets[pos2])
				downstream.append(pos2)
			if pos2 in energizers:
				connections.append(energizers[pos2])
				downstream.append(pos2)
		var level = len(connections)
		if level != 0:
			var divided_output = output_by_side[level] / level
			tile["plasma_supply"] = output_by_side[level]
			tile["plasma_downstream"] = downstream
			for tile2 in connections:
				tile2["plasma_supply"] += divided_output
		else:
			tile["plasma_supply"] = 0
			tile["warning"] = "need_plasma_output"
	for pos in energizers:
		var tile = energizers[pos]
		tile["wasted_plasma_supply"] = tile["plasma_supply"]
		tile["wasted_plasma_power"] = tile["plasma_power"]
		var pos2 = pos + mega_coords[tile.get("rotation", 0)]
		if pos2 in energizers:
			var tile2 = energizers[pos2]
			tile2["chained"] = true
	for pos in energizers:
		var tile = energizers[pos]
		if not "chained" in tile:
			var tracker = [pos]
			while true:
				pos += mega_coords[tile.get("rotation", 0)]
				if pos in tracker:
					break
				else:
					tracker.append(pos)
				if pos in energizers:
					var downstream = energizers[pos]
					downstream["wasted_plasma_supply"] += tile["wasted_plasma_supply"]
					downstream["wasted_plasma_power"] += tile["wasted_plasma_power"]
					downstream["plasma_supply"] += tile["wasted_plasma_supply"]
					downstream["plasma_power"] += tile["wasted_plasma_power"]
					finalize_energizer(tile, pos)
					tile = downstream
				elif pos in turrets:
					turrets[pos]["plasma_supply"] += tile["wasted_plasma_supply"]
					turrets[pos]["plasma_power"] += tile["wasted_plasma_power"]
					finalize_energizer(tile, pos)
					break
				else:
					tile["warning"] = "need_plasma_output"
					break
	check_supply([energizers.values(), turrets.values()], "plasma")
	for pos in collectors:
		var tile = collectors[pos]
		var connections = []
		for delta in mega_coords:
			var pos2 = delta + pos
			if pos2 in armors:
				connections.append(armors[pos2])
			if pos2 in assemblers:
				connections.append(assemblers[pos2])
		var level = len(connections)
		if level != 0:
			var divided_output = output_by_side[level] / level
			tile["material_output"] = output_by_side[level]
			for tile2 in connections:
				tile2["material_supply"] += divided_output
		else:
			tile["material_output"] = 0
			tile["warning"] = "need_material_output"
	check_supply([armors.values(), assemblers.values()], "material")
	for pos in armors:
		for delta in normal_neighbors:
			var pos2 = pos + delta
			if pos2.x < 0 or pos2.x >= size or pos2.y < 0 or pos2.y >= vsize:
				continue
			var tile = get2D(tiles, size, pos2)
			if tile != null and not "armor" in tile[""]:
				if not "covered" in tile:
					tile["covered"] = []
				tile["covered"].append([pos.x, pos.y])
	return stats

func finalize_energizer(energizer, downstream):
	energizer["wasted_plasma_supply"] = 0
	energizer["wasted_plasma_power"] = 0
	energizer['plasma_downstream'] = [downstream]

func shift_coordinate(coord_arr, x, y):
	for i in range(len(coord_arr)):
		coord_arr[i] = [coord_arr[i][0] - x, coord_arr[i][1] - y]
func finalize_ship(tiles, size):
	var stats = analyze_components(tiles, size)
	var hhits = []
	var vhits = []
	var dhits = []
	var map = []
	var turrets = []
	var turret_rotation_count = {0:0, 1:0, 2:0, 3:0, 4:0, 5:0}
	var real_size = stats["size"]
	var mapsize = 0
	if real_size != 0:
		for _i in range(real_size):
			hhits.append([])
			vhits.append([])
			dhits.append([])
		var hrange = stats["hrange"]
		var vrange = stats["vrange"]
		var drange = stats["drange"]
		mapsize = hrange[1] - hrange[0]
		map.resize(mapsize*(vrange[1] - vrange[0]))
		for x in range(hrange[0], hrange[1]):
			for y in range(vrange[0], vrange[1]):
				var tile = tiles[x + y*size]
				if tile != null:
					var mapx = x-hrange[0]
					var mapy = y-vrange[0]
					if "turret" in tile[""]:
						tile['rotation'] = int(tile['rotation'])
						tile["position"] = turret_rotation_count[tile['rotation']]
						turret_rotation_count[tile['rotation']] += 1
						turrets.append([mapx, mapy])
					if "covered" in tile:
						shift_coordinate(tile["covered"], hrange[0], vrange[0])
					if "plasma_downstream" in tile:
						shift_coordinate(tile["plasma_downstream"], hrange[0], vrange[0])
					map[mapx + mapy*mapsize] = tile
					vhits[mapx].append([mapx, mapy])
					hhits[mapy].append([mapx, mapy])
					dhits[x+y-drange[0]].append([mapx, mapy])
		for line in dhits:
			line.sort_custom(self, "by_x")
	stats.erase("hrange")
	stats.erase("vrange")
	stats.erase("drange")
	return {"map":map, "hhits":hhits, "vhits":vhits, "dhits":dhits, "stats":stats, "turrets":turrets, "mapsize": mapsize, "turret_rotations": turret_rotation_count}

func reanalyze_ship(data):
	var tiles = data['map']
	var size = data['mapsize']
	return finalize_ship(tiles, size)

func by_x(a, b):
	return a[0] < b[0]

func check_supply(list_of_list, type):
	for list in list_of_list:
		for tile in list:
			if tile[type+"_supply"] == 0:
				tile["warning"] = "need_"+type+"_supply"

func get_component_parts(tile):
	if not tile:
		return [null]
	if not tile is Dictionary:
		tile = {"": tile}
	var type = tile[""]
	var result
	if type == "redirect":
		return [null]
	elif type == "pseudocore":
		result = ["pseudocore-top", "core-base"]
	elif "core" in type or "turret" in type or "thruster" in type or type == "assembler":
		result = [type + "-top", type + "-base"]
	elif type is String:
		result = [type]
	var rotation = tile.get("rotation", 0)
	if rotation % 3 and have_full_rotation(result[0]):
		result[0] += "-rotate"
	if "super" in type:
		if "flip" in tile and tile["flip"]:
			if rotation in [4, 5]:
				result[0] += "-flip"
				result[1] += "-flip"
		else:
			if rotation in [1, 2]:
				result[0] += "-flip"
				result[1] += "-flip"
	return result

func Vector2Mul(a, b):
	return Vector2(a.x*b.x, a.y*b.y)

func set_texture(renderer: Sprite, part):
	part = part.trim_suffix('-rotate')
	var id = tileset.find_tile_by_name(part)
	renderer.region_enabled = true
	renderer.region_rect = tileset.tile_get_region(id)
	renderer.texture = tileset.tile_get_texture(id)
	renderer.offset = tileset.tile_get_texture_offset(id)

func have_full_rotation(tilename):
	return tilename == "energizer" or "thruster-top" in tilename or "turret-top" in tilename

func set_tile(map: TileMap, pos, tile, imgname):
	if not imgname:
		map.set_cellv(pos, -1)
	else:
		var rotation = 0 if "base" in imgname else tile.get("rotation", 0)
		var flip = "flip" in tile and tile["flip"]
		match rotation:
			0:
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), false, flip)
			3:
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), true, flip)
			_:
				var flipx = not rotation % 2
				var flipy = rotation <= 3
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), flipx, flipy)
