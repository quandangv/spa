extends Node

const super_coords = [Vector2(-1, 1), Vector2(0, 1)]
const super_flip_coords = [Vector2(0, -1), Vector2(1, -1)]
const mega_extra_coords = [Vector2(-1, 0), Vector2(1, 0)]
const mega_coords = [Vector2(-1, 0), Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 1)]

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
						offset.x -= tilset_cell_size/4
						offset.y -= tilset_cell_size/2
					else:
						offset.x -= tilset_cell_size/2
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

const normal_neighbors = super_coords + super_flip_coords + mega_extra_coords
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

const generator_output = [0, 6.0, 9.0, 11.0, 11.0, 11.0, 12.0]
func analyze_components(tiles, size):
	var stats = {"thrust":0, "radar":0, "armor": 0, "shield":0, "regeneration":0}
	var generators = {}
	var energizers = {}
	var turrets = {}
	for x in range(size):
		for y in range(size):
			var tile = tiles[x + y*size]
			if tile == null: continue
			var pos = Vector2(x, y)
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
					if tile["flip"]:
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
					stats["armor"] += 1
				"superarmor":
					stats["armor"] += 3
					add_dict(stats, "reflect")
					tile["reflect"] = true
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
					add_dict(stats, "assembly")
					tile["assembly"] = true
				"collector":
					stats["regeneration"] += 1
	for pos in generators:
		var tile = generators[pos]
		var connections = []
		for delta in mega_coords:
			var pos2 = delta + pos
			if pos2 in turrets:
				connections.append(turrets[pos2])
			if pos2 in energizers:
				connections.append(energizers[pos2])
		var level = len(connections)
		if level != 0:
			var divided_output = generator_output[level] / level
			tile["plasma_supply"] = generator_output[level]
			for tile2 in connections:
				tile2["plasma_supply"] += divided_output
			tile.erase("warning")
		else:
			tile["warning"] = "no turret or energizer to receive output"
	for pos in energizers:
		var tile = energizers[pos]
		tile["wasted_plasma_supply"] = tile["plasma_supply"]
		tile["wasted_plasma_power"] = tile["plasma_power"]
		var pos2 = pos + mega_coords[tile["rotation"]]
		if pos2 in energizers:
			var tile2 = energizers[pos2]
			tile2["chained"] = true
	for pos in energizers:
		var tile = energizers[pos]
		if not "chained" in tile:
			var tracker = [pos]
			while true:
				pos += mega_coords[tile["rotation"]]
				if pos in tracker:
					break
				else:
					tracker.append(pos)
				if pos in energizers:
					energizers[pos]["wasted_plasma_supply"] += tile["wasted_plasma_supply"]
					energizers[pos]["wasted_plasma_power"] += tile["wasted_plasma_power"]
					energizers[pos]["plasma_supply"] += tile["wasted_plasma_supply"]
					energizers[pos]["plasma_power"] += tile["wasted_plasma_power"]
					clear_energizer(tile)
					tile = energizers[pos]
				elif pos in turrets:
					turrets[pos]["plasma_supply"] += tile["wasted_plasma_supply"]
					turrets[pos]["plasma_power"] += tile["wasted_plasma_power"]
					clear_energizer(tile)
					break
				else:
					tile["warning"] = "no turret or energizer to receive output"
					break
	return stats

func clear_energizer(e):
	e["wasted_plasma_supply"] = 0
	e["wasted_plasma_power"] = 0
	e.erase("warning")
func get_component_parts(tile):
	if not tile:
		return [null]
	if not tile is Dictionary:
		tile = {"": tile, "rotation": 0}
	var type = tile[""]
	var result
	if type == "redirect":
		return [null]
	elif type == "pseudocore":
		result = ["pseudocore-top", "core-base"]
	elif "core" in type or "turret" in type or "thruster" in type:
		result = [type + "-top", type + "-base"]
	elif type is String:
		result = [type]
	if tile["rotation"] % 3 and have_full_rotation(result[0]):
		result[0] += "-rotate"
	if "super" in type:
		if "flip" in tile and tile["flip"]:
			if tile["rotation"] in [1, 2]:
				result[0] += "-flip"
				result[1] += "-flip"
		else:
			if tile["rotation"] in [4, 5]:
				result[0] += "-flip"
				result[1] += "-flip"
	return result

func Vector2Mul(a, b):
	return Vector2(a.x*b.x, a.y*b.y)

func set_texture(renderer: Sprite, part):
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
		var rotation = 0 if "base" in imgname else tile["rotation"]
		var flip = "flip" in tile and tile["flip"]
		match rotation:
			0:
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), false, flip)
			3:
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), true, flip)
			_:
				var flipx = not rotation % 2
				var flipy = rotation > 3
				map.set_cellv(pos, tileset.find_tile_by_name(imgname), flipx, flipy)
