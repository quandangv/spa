extends LineEdit

export var helper_path:NodePath
onready var helper = get_node(helper_path)
export var join_path:NodePath
onready var join_button = get_node(join_path)
export var host_path:NodePath
onready var host_button = get_node(host_path)
export var color_path:NodePath
onready var color_picker = get_node(color_path)
export var close_button_path:NodePath
onready var close_button = get_node(close_button_path)
var helper_action = null
var address = null

func _ready():
  host_button.connect("press_original", self, "prep_host_game")
  join_button.connect("press_original", self, "prep_join_game")
  host_button.connect("press_other", self, "close_connection")
  join_button.connect("press_other", self, "close_connection")
  Multiplayer.connect("client_connected", self, "join_success")
  Multiplayer.connect("client_connect_failed", self, "join_failure")
  Multiplayer.connect("connection_closed", self, "clear_address")

func clear_address():
  address = null

func not_already_initialized():
  var tree = get_tree()
  if tree.network_peer == null:
    return true
  elif tree.is_network_server():
    show_textbox(false, "already hosting", "close", "Okay")
  else:
    show_textbox(false, "already joined", "close", "Okay")
func prep_host_game():
  if not_already_initialized():
    show_textbox(true, "", "host_game", "Use Port", String(Multiplayer.default_port))
func host_game():
  if text == "":
    text = placeholder_text
  var error = Multiplayer.host_game(int(text))
  if not error:
    host_button.is_original = false
    join_button.disabled = true
    address = IP.get_local_addresses()[0] + ":" + String(Multiplayer.my_port)
    show_address()
  else:
    show_textbox(false, error, "prep_host_game", "Try different port")
func show_address():
  show_textbox(false, address, "copy", "Copy address")

func prep_join_game():
  if not_already_initialized():
    show_textbox(true, "", "join_game", "Join with address", OS.clipboard)
func join_game():
  if text == "":
    text = placeholder_text
  var error = Multiplayer.join_game(text)
  if not error:
    join_button.is_original = false
    host_button.disabled = true
    address = text
    show_textbox(false, "joining...", "close", "Okay")
  else:
    address = null
    show_textbox(false, error, "prep_join_game", "Try different address")

func join_success():
  show_textbox(false, "joined!", "close", "Yay!")

func join_failure():
  address = null
  show_textbox(false, "failed to join", "prep_join_game", "Try different address")

func prep_name_player():
  show_textbox(true, Storage.player["name"], "name_player", "Select Name")
  color_picker.color = Storage.player["color"]
  color_picker.visible = true
func name_player():
  color_picker.visible = false
  Storage.set_player_display(text, color_picker.color)
  show_textbox(false, text, "close", "Changed")

func close_connection():
  host_button.is_original = true
  join_button.is_original = true
  host_button.disabled = false
  join_button.disabled = false
  close_button.disabled = true
  self.visible = false
  Multiplayer.close_connection()

func show_textbox(editable, text, action, helper_text, placeholder = ""):
  self.editable = editable
  self.text = text
  helper_action = action
  helper.text = helper_text
  self.visible = true
  self.placeholder_text = placeholder
  close_button.disabled = false

func copy():
  OS.clipboard = text

func helper_pressed():
  if helper_action:
    call(helper_action)

func close():
  if address != null:
    show_address()
  self.visible = false

func set_visible(value):
  .set_visible(value)
  helper.visible = value
