extends Node

const SEL_POSITION = 0
const SEL_TYPE = 1

export var halfsize:int = 10
export(TileSet) var tile_set
export(NodePath) var type_buttons_path
export(NodePath) var upgrade_buttons_path
export(NodePath) var ghost_path
var tiles: Array
var size: int
var selected_pos
var type_buttons_anim: AnimationPlayer
var upgrade_buttons
var ghost
onready var comp_utils = get_node("/root/utils/component")

func _ready():
	type_buttons_anim = get_node(type_buttons_path).find_node("anim")
	upgrade_buttons = get_node(upgrade_buttons_path)
	ghost = get_node(ghost_path)
	size = halfsize*2+1
	$map.init(halfsize, tile_set)
	$ui/base/toolbar.connect("rotation_changed", self, "rotation_changed")
	$ui/base/toolbar.connect("selection_changed", self, "tool_changed")
	for type in ["super", "super-flip", "mega"]:
		upgrade_buttons.get_node(type).connect("pressed", self, "upgrade_selected", [type])
	tool_changed(null)
	reset_tiles()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var show_ghost = false
		var mouse = $map.get_mouse_pos()
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
			set_tile(mouse, null)
			unselect_tile()
		elif not Input.is_mouse_button_pressed(BUTTON_LEFT):
			show_ghost = true
		update_ghost(show_ghost, mouse)
	if event is InputEventMouseButton:
		var mouse = $map.get_mouse_pos()
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
			set_tile(mouse, null)
		elif Input.is_mouse_button_pressed(BUTTON_LEFT):
			var selected = $ui/base/toolbar.get_selected()
			if selected:
				set_tile(mouse, {"": selected, "rotation": $ui/base/toolbar.rotation})
			elif inrange(mouse):
				var new_selected_tile
				while true:
					new_selected_tile = tiles[get_tiles_index(mouse)]
					if new_selected_tile == null or mouse == selected_pos:
						unselect_tile()
					elif new_selected_tile[""] == "redirect":
						mouse = new_selected_tile["target"]
						continue
					else:
						select_tile(mouse, new_selected_tile)
					break

func upgrade_selected(rank):
	if selected_pos == null: return
	var flip = false
	var type = tiles[get_tiles_index(selected_pos)][""]
	var tile = {"rotation": $ui/base/toolbar.rotation}
	if rank == "super":
		tile["occupies"] = comp_utils.super_coords
	elif rank == "super-flip":
		tile["occupies"] = comp_utils.super_flip_coords
		rank = "super"
		tile["flip"] = true
	elif rank == "mega":
		tile["occupies"] = comp_utils.mega_coords
	tile[""] = rank + type
	set_tile(selected_pos, tile)
	unselect_tile()

func unselect_tile():
	if selected_pos != null:
		selected_pos = null
		$map/selection/anim.play_backwards("appear")
		type_buttons_anim.play("appear")
		upgrade_buttons.disappear()
		$ui/base/stats.selection_changed(null)

func select_tile(pos, tile):
	$ui/base/stats.selection_changed(tile)
	$ui/base/toolbar.rotation = tile["rotation"]
	selected_pos = pos
	comp_utils.set_texture($map/selection, comp_utils.get_component_parts(tile)[-1])
	$map/selection.flip_v = false
	if "super" in tile[""]:
		if tile.get("flip", false):
			$map/selection.flip_v = true
			$map/selection.position = comp_utils.map_to_local(pos + Vector2(0.8660254038, -0.8660254038*2))
		else:
			$map/selection.position = comp_utils.map_to_local(pos + Vector2(0.15, -0.3))
	else:
		$map/selection.position = comp_utils.map_to_local(pos)
	$map/selection/anim.play("appear")
	type_buttons_anim.play_backwards("appear")
	var show_super = check_near(pos, tile[""], comp_utils.super_coords)
	var show_super_flip = check_near(pos, tile[""], comp_utils.super_flip_coords)
	upgrade_buttons.appear(tile[""], show_super, show_super_flip,
		show_super and show_super_flip and check_near(pos, tile[""], comp_utils.mega_extra_coords))

func check_near(pos, type, delta):
	for d in delta:
		var neighbor = pos + d
		if not inrange(neighbor):
			return false
		var tile = tiles[get_tiles_index(neighbor)]
		if tile == null or tile[""] != type:
			return false
	return true

func inrange(pos):
	return pos.x >= -halfsize and pos.x <= halfsize and  pos.y >= -halfsize and pos.y <= halfsize

func tool_changed(selection):
	ghost.set_process(selection != null)
	ghost.visible = selection != null
	if selection != null:
		$map/selection/anim.play_backwards("appear")
		ghost.target_modulate = Color.transparent
		ghost.get_node("img").set_component(selection)
		ghost.position = $map.get_local_mouse_position()
	else:
		ghost.target_modulate = Color.transparent

func rotation_changed(rotation):
	ghost.target_rotation = rotation * PI / 3
	if selected_pos != null:
		var tile = get_tile(selected_pos)
		tile["rotation"] = rotation
		set_layers(selected_pos, tile)

func get_tile(pos):
	return tiles[get_tiles_index(pos)]

func update_ghost(show, pos):
	ghost.target_modulate = Color.white if inrange(pos) and show else Color.transparent
	ghost.target_pos = comp_utils.map_to_local(pos)

func reset_tiles():
	$map/base.clear()
	$map/top.clear()
	tiles = []
	tiles.resize(size*size)

func set_layers(pos, tile):
	var parts = comp_utils.get_component_parts(tile)
	var rotation = $ui/base/toolbar.rotation
	comp_utils.set_tile($map/top, pos, tile, parts[0])
	if len(parts) > 1:
		comp_utils.set_tile($map/base, pos, tile, parts[1])
	else:
		$map/base.set_cellv(pos, -1)

func get_tiles_index(pos):
	return pos.x + halfsize + (pos.y  + halfsize)* size

func set_tile(pos, tile, reanalyze = true):
	if not inrange(pos):
		return
	if tile == null:
		tile = null
	var index = get_tiles_index(pos)
	var current = tiles[index]
	if current == tile:
		return
	if current != null:
		if current[""] == "redirect":
			set_tile(current["target"], null, false)
		if "occupies" in current:
			for delta in current["occupies"]:
				tiles[get_tiles_index(pos + delta)] = null
	tiles[index] = tile
	if tile != null:
		if "occupies" in tile:
			for delta in tile["occupies"]:
				set_tile(pos + delta, {"": "redirect", "target": pos}, false)
	set_layers(pos, tile)
	if reanalyze:
		var stats = comp_utils.analyze_components(tiles, size)
		$ui/base/stats.set_stat(stats)
