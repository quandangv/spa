extends Node

const player_path = "user://player.json"
const ranks = {"ensign": 1}
var player = {"rank": 0}

func _ready():
  var saved = File.new()
  if saved.file_exists(player_path):
    saved.open(player_path, File.READ)
    player = parse_json(saved.get_line())

func save():
  var saved = File.new()
  saved.open(player_path, File.WRITE)
  saved.store_line(to_json(player))

func give_rank(name):
  player["rank"] = max(player["rank"], ranks[name])
