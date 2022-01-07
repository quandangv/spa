extends Node2D

export var halfsize = 5
export var grid_color: Color
export(Vector2) var mapping_offset

onready var comp_utils = get_node("/root/utils/component")

func init(halfsize, tile_set):
	self.halfsize = halfsize
	for child in get_children():
		if child is TileMap:
			child.cell_custom_transform = comp_utils.tile_transform
			child.tile_set = tile_set
			child.cell_size = Vector2(1, 1)
			child.mode = TileMap.MODE_CUSTOM
			child.centered_textures = true

func get_mouse_pos():
	var pos = get_local_mouse_position()
	return comp_utils.local_to_map(pos)

func _draw():
	for x in range(-halfsize, halfsize+1):
		for y in range(-halfsize, halfsize+1):
			var pos = comp_utils.map_to_local(Vector2(x, y))
			draw_circle(pos, 50, grid_color)
	draw_circle(Vector2.ZERO, 50, grid_color)
# Uncomment this to draw grid
#	for i in range(dimensions):
#		draw_line(map_to_local(i+0.5, -0.5), map_to_local(i+0.5, 9.5), Color(255, 0, 0), 1)
#		draw_line(map_to_local(-0.5, i+0.5), map_to_local(9.5, i+0.5), Color(255, 0, 0), 1)

# Uncomment to print map coordinate every click
#func _input(event):
#	if event is InputEventMouseButton:
#		var pos = get_local_mouse_position()
#		print(local_to_map(pos.x, pos.y))
