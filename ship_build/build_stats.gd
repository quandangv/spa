extends MarginContainer

export(Color) var safe_color
export(Color) var danger_color

var stat_bars = {}
var autohide_bars = []

func _ready():
	for bar in $container.get_children():
		bar.get_node("label").text = bar.name
		stat_bars[bar.name] = bar
		if not bar.visible:
			autohide_bars.append(bar.name)

func set_stat(stats):
	for name in stats:
		if name in stat_bars:
			stat_bars[name].set_value(stats[name])

func selection_changed(new_tile):
	for bar in autohide_bars:
		if new_tile != null and bar in new_tile:
			stat_bars[bar].set_visibility(true)
			if not new_tile[bar] is bool:
				stat_bars[bar].set_value(new_tile[bar])
		else:
			stat_bars[bar].set_visibility(false)
