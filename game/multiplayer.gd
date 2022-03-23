extends Node

signal client_connected
signal client_connect_failed
signal my_stat_changed
signal network_changed
signal connection_closed

const default_port = 10753
const max_player = 4

var my_port = null
var next_anchor = null
var player_info = {}
var player_stats = {}
var my_stat = null
var unique_id = 0
onready var spawner = $spawner

func get_unique_id():
  unique_id = (unique_id + 1) % 2000000000
  return unique_id * max_player + my_stat["anchor"]

func _ready():
  get_tree().connect("network_peer_connected", self, "_player_connected")
  get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
  get_tree().connect("connected_to_server", self, "_connected_ok")
  get_tree().connect("connection_failed", self, "_connected_fail")
  get_tree().connect("server_disconnected", self, "_server_disconnected")
  Storage.connect("player_info_changed", self, "update_my_info")

func update_my_info():
  if GameUtils.networking:
    rpc("update_player_info", Storage.player)

func serialize(item):
  var result = item.serialize()
  result["_scene"] = item.get_meta("_scene")
  result["_name"] = item.name
  return result

func _player_connected(id):
  rpc_id(id, "update_player_info", Storage.player)
  rpc_id(id, "update_player_stat", my_stat)
  for item in spawner.spawned.get_children():
    if item.is_network_master():
      rpc_id(id, "spawn", serialize(item))
  if get_tree().is_network_server():
    var new_stat = {"anchor":next_anchor}
    rpc_id(id, "sync_init", new_stat)
    next_anchor += 1

func _player_disconnected(id):
    player_info.erase(id)

func _connected_ok():
    emit_signal("client_connected")

func _connected_fail():
    emit_signal("client_connect_failed")

func _server_disconnected():
    pass

remote func update_player_info(info):
  var id = get_tree().get_rpc_sender_id()
  player_info[id] = info

remote func update_player_stat(stat):
  player_stats[get_tree().get_rpc_sender_id()] = stat

func set_my_stat(stat):
  my_stat = stat
  emit_signal("my_stat_changed")

remote func sync_init(stat):
  set_my_stat(stat)
  rpc("update_player_stat", stat)

func spawn_local(scene_name, anchor = null):
  var instance = spawner.scenes[scene_name].instance()
  instance.set_meta("_scene", scene_name)
  if my_stat != null:
    instance.name = String(instance.name) + String(get_unique_id())
    var my_id = get_tree().get_network_unique_id()
    instance.set_network_master(my_id, true)
    spawner.put(my_stat["anchor"] if anchor == null else anchor, instance)
    rpc("spawn", serialize(instance))
    instance.color = Storage.player["color"]
  else:
    if anchor == null:
      spawner.spawned.add_child(instance)
    else:
      spawner.put(anchor, instance)
  instance.connect("destroyed", instance, "queue_free")
  return instance

remote func spawn(data):
  var id = get_tree().get_rpc_sender_id()
  var spawn_source = player_info[id]
  var instance = spawner.scenes[data["_scene"]].instance()
  instance.set_meta("_scene", data["_scene"])
  instance.name = data["_name"]
  instance.color = player_info[id]["color"]
  instance.init_deserialize(data)
  instance.set_network_master(id, true)
  instance.starting_side = "enemy"
  spawner.spawned.add_child(instance)
  instance.color = spawn_source["color"]
  instance.connect("destroyed", instance, "queue_free")
  instance.deserialize(data)

func close_connection():
  get_tree().network_peer.close_connection()
  get_tree().network_peer = null
  emit_signal("connection_closed")
  spawner.clear()
  GameUtils.networking = false

func host_game(port):
  if get_tree().network_peer == null:
    var peer = NetworkedMultiplayerENet.new()
    if peer.create_server(port, max_player) != OK:
      return "can't create server"
    get_tree().network_peer = peer
    GameUtils.networking = true
    my_port = port
    spawner.clear()
    emit_signal("network_changed")
    set_my_stat({"anchor":0})
    next_anchor = 1
    $seed_sync.start()
  else:
    return "already connected"

func join_game(address):
  if get_tree().network_peer == null:
    var split = address.split(":")
    if len(split) != 2:
      return "invalid address"
    var peer = NetworkedMultiplayerENet.new()
    if peer.create_client(split[0], int(split[1])) != OK:
      return "can't create client"
    get_tree().network_peer = peer
    GameUtils.networking = true
    spawner.clear()
    emit_signal("network_changed")
    set_my_stat(null)
    player_stats.clear()
    $seed_sync.stop()
  else:
    return "already connected"
