extends Node

const MAX_FOOTPRINTS_STORED = 30

const ACTION_NONE    = ""
const ACTION_DIGGING = "G"
const ACTION_DOWSING = "W"
const ACTION_WRITING = "T"
const ACTION_DIED    = "D"
const ACTION_RESPAWN = "R"

const UPGRADE_SHOVEL = "SHOVEL"

# Named callbacks
const CB_INSERT_COIN = "on_insert_coin"
const CB_DISCONNECTED = "on_disconnected"
const CB_PLAYER_JOINED = "on_player_joined"
const CB_RECEIVE_DEATH_LIST = "receive_death_list"
const CB_RECEIVE_INSCRIPTION_LIST = "receive_inscription_list"
const CB_DYNAMIC_PLAYER_QUIT = "player_quit_"
const CB_DYNAMIC_PLAYER_DEATH = "player_death_"
const CB_DYNAMIC_PLAYER_INSCRIPTION = "player_inscription_"


const PLAYROOM_PERSIST_DEATH_LIST = "deaths"
const PLAYROOM_PERSIST_INSCRIPTIONS_LIST = "comments"
# To Test with Playroom connectivity
# In the upper-right, click the "Remote Debug" option and
# select "Run in Browser". 
# If "Run In Browser" doesn't appear, the export settings for HTML need to be fixed.
# Setup of export settings: https://docs.joinplayroom.com/usage/godot#setup

# Signals for anytime a player does something in the same zone as us
# As the player moves through the world
# It is important that they call Playroom.connect_room(...) 
# with the zone name they are currently in
# For example, if at an Oasis, should connect to `Oasis1_1`
# If in the world, should connect to `Zone1_1`, `Zone2_1`, etc
# The number after the underscore is the sharding of that room
# as each room can only accommodate a certain number of players
signal server_connect_started(room_name: String)
signal server_connected(room_name: String)
signal server_disconnected(room_name: String)

signal player_joined(room_name: String, player_name: String)
signal player_left(room_name: String, player_name: String)

# Most likely not needed for game
signal deaths_updated(room_name: String, players: Array[String])
signal inscriptions_updated(room_name: String, inscriptions: Array[String])

# Broadcasted when info about a player's death/inscription has been loaded
# Can be used immediately, or can be requested through 
# Playroom.get_death(...) or Playroom.get_inscription(...)
signal death_loaded(room_name: String, player_name: String, location: Vector2, footprints: Array[Vector2])
signal death_load_failed(room_name: String, player_name: String)
signal inscription_load_failed(room_name: String, key: String)
signal inscription_loaded(room_name: String, key: String, location: Vector2, phrase: int, word: int)

# From the Dev dashboard of dev.joinplayroom.com
# This is not a secret so ok to check in
const GAME_ID := "vdZFUVJZ81aZvf4ITXYd"

# Suggested by one of the devs as the max
const MAX_PLAYERS_ROOM := 20

# References to the Javascript object connectors to communicate with
# the web side
var _playroom: JavaScriptObject = null
var _console: JavaScriptObject = null

# Keep a reference to the callback so it doesn't get garbage collected
# TODO: this should probably be purged after the callback is no longer used
var jsBridgeReferences = []
var namedReferences = {}

# Need to use their room codes, not just any values we want
# More can be generated by not specifying a room code.
# Printed out on connect in the console log of web browser
const GLOBAL_ROOMS = [
	"PER_4EP6RJFD4METR6ALBQFEGH43HP",
]

# Room Code of the current room we are connected to
var _current_room: String = ""
var connected: bool = false

# Check if the player has entered their name
# Into the room's global username lookup list (they should only do it once)
# String (room name) -> bool (inserted into index)
var _created_death_tracker: Dictionary = {}
var _created_comment_tracker: Dictionary= {}

# Generated at startup
# This will be a persistent ID the player uses across all rooms
var _my_user_id = ""

# Players can generate more than one inscription
# overwrite their old ones if they try to do more
const MAX_PLAYER_INSCRIPTIONS = 4
var inscription_offset := 0
const MAX_PLAYER_DEATHS = 1
var death_offset := 0

# Tracked state for all players. 
# Dict -> Dict -> PlayerState
# Room -> PlayerName -> PlayerState
# Values are state objects that you can call .getState(...) on
var _tracked_room_players = {}

# All known IDs that we have content for
# String (player name) -> Death/Inscription data
var _tracked_deaths = {}
var _tracked_inscriptions = {}

# Since this data is async, process them one at a time until we have them all
# TODO: implement queued persistent data fetches
var _processing_persisted_data = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_my_user_id = "profour" # TODO: enable for prod -> _random_player_name()
	
	_playroom = JavaScriptBridge.get_interface("Playroom")
	_console = JavaScriptBridge.get_interface("console")
 
## Connect to a room (disconnect from the other if we were connected)
func connect_room(room_name: String):
	if _current_room != "":
		# TODO: disconnect from previous room and
		# join the new room
		# TODO: devs said disconnects arent possible right now
		return
	
	_current_room = room_name
	
	# Setup all of the options we need for
	# the game room to be created/joined
	var initOptions = JavaScriptBridge.create_object("Object")
	initOptions["gameId"] = GAME_ID
	initOptions["roomCode"] = room_name
	initOptions["skipLobby"] = true
	initOptions["maxPlayersPerRoom"] = MAX_PLAYERS_ROOM
	initOptions["persistentMode"] = true
	
	server_connect_started.emit(_current_room)
	
	# Join the server
	_playroom.insertCoin(
		initOptions, 
		_bridgeToJS(_on_insert_coin, CB_INSERT_COIN),
		_bridgeToJS(_on_disconnected, CB_DISCONNECTED)
	)

func whoami() -> String:
	if connected:
		return _playroom.myPlayer().state.profile.name
	
	return "UNKNOWN"

# Update the player's position so others can see them
func update_my_pos(pos: Vector2) -> void:
	if connected:
		_playroom.myPlayer().setState("pos", JSON.stringify([pos.x, pos.y]))

# Ask for the current position of other players we know of
func get_other_player_position(player: String) -> Vector2:
	if _current_room not in _tracked_room_players:
		return Vector2.ZERO
	
	if player not in _tracked_room_players[_current_room]:
		return Vector2.ZERO
	
	var json_data = _tracked_room_players[_current_room][player].getState("pos")
	
	if json_data == null:
		return Vector2.ZERO
	
	var parsed: Variant = JSON.parse_string(json_data)
	
	if parsed == null:
		return Vector2.ZERO
	
	if typeof(parsed) != TYPE_ARRAY or len(parsed) != 2:
		return Vector2.ZERO
	
	return Vector2(parsed[0], parsed[1])

func set_player_action(action: String, position: Vector2):
	if connected:
		_playroom.myPlayer().setState("action", action)

func set_player_upgrade(upgrade: String) -> void:
	if connected:
		_playroom.myPlayer().setState(upgrade, "T") # abbreviated True

func get_player_upgrade(player: String, upgrade: String) -> bool:
	if _current_room not in _tracked_room_players:
		return false
	
	if player not in _tracked_room_players[_current_room]:
		return false
	
	var action_data = _tracked_room_players[_current_room][player].getState(upgrade)
	
	if action_data == null:
		return false
	
	return action_data == "T" # abbreviated true

func get_other_player_action(player: String) -> String:
	if _current_room not in _tracked_room_players:
		return ""
	
	if player not in _tracked_room_players[_current_room]:
		return ""
	
	var action_data = _tracked_room_players[_current_room][player].getState("action")
	
	if action_data == null:
		return ""
	
	return action_data
	
 
# Request the list of deaths in the current room we are connected to
# This will get the list of all playernames with deaths
# and the start the individual requests for each playername death info
func request_death_list() -> void:
	_playroom.getPersistentData(PLAYROOM_PERSIST_DEATH_LIST) \
		.then(_bridgeToJS(_receive_death_list, CB_RECEIVE_DEATH_LIST))


# Request the list of inscriptions in the current room we are connected to
# This will get the list of all playernames with inscriptions
# and the start the individual requests for each playername inscription info
func request_inscriptions_list() -> void:
	# TODO: break this into parts by zone
	_playroom.getPersistentData(PLAYROOM_PERSIST_INSCRIPTIONS_LIST) \
		.then(_bridgeToJS(_receive_inscription_list, CB_RECEIVE_INSCRIPTION_LIST))

func request_death_data(death_key: String) -> void:
	_playroom.getPersistentData(death_key) \
		.then(_bridgeToJS(_receive_player_death.bind(death_key), 
			CB_DYNAMIC_PLAYER_DEATH + death_key))
		
func request_inscription_data(inscription_key: String) -> void:
	_playroom.getPersistentData(inscription_key) \
		.then(_bridgeToJS(_receive_player_inscription.bind(inscription_key), 
			CB_DYNAMIC_PLAYER_INSCRIPTION + inscription_key))

func add_inscription(position: Vector2, phrase: int, word: int) -> void:
	if not connected:
		return
	
	var player_key: String = _create_inscription_key(_my_user_id, inscription_offset)
	inscription_offset = (inscription_offset+1) % MAX_PLAYER_INSCRIPTIONS
	
	if not _created_comment_tracker.has(player_key):
		_created_comment_tracker[player_key] = true
		
		# Add the player's comment key into the inscription tracker
		# so other players know the key exists
		await _playroom.insertPersistentData(
			PLAYROOM_PERSIST_INSCRIPTIONS_LIST,
			player_key
		)
	
	_playroom.setPersistentData(
		player_key,
		JSON.stringify({
			"p": [position.x, position.y],
			"t": phrase,
			"w": word
		})
	)
	
	

# Register where the player died
# And include some of their footprints up to the point they died
func add_death_location(position: Vector2, footprints: Array[Vector2]) -> void:
	if _current_room == "":
		return
	
	var death_key = _create_player_death_key(_my_user_id, death_offset)
	death_offset = (death_offset + 1) % MAX_PLAYER_DEATHS
	
	if not _created_death_tracker.has(death_key):
		_created_death_tracker[death_key] = true
		
		# Add the player's ID into the death track 
		# so other players know the key exists
		await _playroom.insertPersistentData(
			PLAYROOM_PERSIST_DEATH_LIST,
			death_key
		)
	
	var trail: Array[Array] = []
	for v in footprints:
		trail.append([v.x, v.y])
	
	_playroom.setPersistentData(
		death_key,
		JSON.stringify({
			"p": [position.x, position.y],
			"f": trail
		})
	)

# Called when the player has connected to a room successfully
func _on_insert_coin(args: Variant):
	print("Joined room successfully: ", _current_room, " Args: ", args)
	print("Room claims to be: ", _playroom.getRoomCode())
	connected = true
	_current_room = _playroom.getRoomCode()
	server_connected.emit(_current_room)
	
	# Start with fresh room player tracking on new connections
	_tracked_room_players[_current_room] = {}
	
	# Attach the callback to get information when players join
	_playroom.onPlayerJoin(_bridgeToJS(_on_player_join, CB_PLAYER_JOINED))
	
	#add_death_location(Vector2(0,0), [Vector2.ZERO, Vector2.ONE])
	
	_console.log("Joined as player: ", _playroom.me())

# Called when we lose our connection to the room
func _on_disconnected(args: Variant):
	print("Disconnected from room. Args: ", args)
	server_disconnected.emit(_current_room)
	
	# Clear out all player tracked info since we left the room
	# and will no longer be received info for the players
	if _current_room in _tracked_room_players:
		var players = _tracked_room_players[_current_room]
		for player in players.keys():
			player_left.emit(_current_room, player)
		
		_tracked_room_players.erase(_current_room)
	
	connected = false
	_current_room = ""

	# TODO: we should attempt to reconnect
 
# Called when a new player joins the game
# TODO: The first call is always for us I believe?
func _on_player_join(args: Variant):
	# Javascript object madness
	var player_info: Variant = args[0]
	var state: Variant = player_info.state
	
	var player_name = state.profile.name
	
	if _current_room not in _tracked_room_players:
		_tracked_room_players[_current_room] = {}
	
	_tracked_room_players[_current_room][player_name] = player_info
	
	# Register for callbacks when the player quits/disconnects
	player_info.onQuit(_bridgeToJS(
		_on_player_quit.bind(_current_room, player_name),
		CB_DYNAMIC_PLAYER_QUIT + player_name
	))
	
	# Send out that the player joined
	player_joined.emit(_current_room, player_name)

# Called when a player quits
func _on_player_quit(args: Variant, room_name: String, player_name: String) -> void:
	print("[Playroom] Player quit the room: ", room_name, " Player: ", player_name)
	player_left.emit(room_name, player_name)
	
	#cleanup our callback as it is consumed now
	var cb_name = CB_DYNAMIC_PLAYER_QUIT + player_name
	if cb_name in namedReferences:
		namedReferences.erase(cb_name)


# Callback for the list of valid keys we can use for the persisted deaths
func _receive_death_list(args: Variant) -> void:
	if args != null and args[0] != null and "length" in args[0]:
		print("Death Map Length: ", args[0].length)
		
		var player_names: Array[String] = []
		
		for i in range(args[0].length):
			player_names.push_back(args[0][i])
		
		deaths_updated.emit(_current_room, player_names)
	else:
		print("Death list came back null or non-array.")

	# Don't need to delete the CB as it will be overwritten

func _receive_player_death(args: Variant, death_key: String) -> void:
	print("Received player death data: ", death_key)
	print("With args: ", args[0])
	var death_data = JSON.parse_string(args[0])
	
	print("JSON Parsed object: ", death_data)
	
	# Cleanup the callback as it has completed
	var cb_name = CB_DYNAMIC_PLAYER_DEATH + death_key
	if cb_name in namedReferences:
		namedReferences.erase(cb_name)
	
	if "p" in death_data and "f" in death_data:
		var raw_position = death_data["p"]
		if typeof(raw_position) != TYPE_ARRAY or len(raw_position) != 2:
			print("Death's position field failed to validate: " + str(typeof(raw_position)))
			death_load_failed.emit(_current_room, death_key)
			return
		
		var raw_footprints = death_data["f"]
		if typeof(raw_footprints) != TYPE_ARRAY:
			print("Death's footprint field failed to validate: " + str(typeof(raw_footprints)))
			death_load_failed.emit(_current_room, death_key)
			return
			
		
		var pos = Vector2(raw_position[0], raw_position[1])
		
		var fp: Array[Vector2] = []
		for i in range(min(len(raw_footprints), MAX_FOOTPRINTS_STORED)):
			var raw_coord = raw_footprints[i]
			if typeof(raw_coord) != TYPE_ARRAY or len(raw_coord) != 2:
				print("Death's footprint coord field failed to validate: " + str(typeof(raw_coord)))
				death_load_failed.emit(_current_room, death_key)
				return
			
			fp.push_back(Vector2(raw_coord[0], raw_coord[1]))
		
		death_loaded.emit(_current_room, death_key, pos, fp)

func _receive_player_inscription(args: Variant, inscription_key: String) -> void:
	print("Received inscription data: ", inscription_key)
	print("With args: ", args[0])
	var data = JSON.parse_string(args[0])
	
	print("JSON Parsed object: ", data)
	
	# Cleanup the callback as it has completed
	var cb_name = CB_DYNAMIC_PLAYER_INSCRIPTION + inscription_key
	if cb_name in namedReferences:
		namedReferences.erase(cb_name)
	
	if "p" in data and "t" in data and "w" in data:
		var raw_position = data["p"]
		if typeof(raw_position) != TYPE_ARRAY or len(raw_position) != 2:
			print("Inscription's position field failed to validate: " + str(typeof(raw_position)))
			inscription_load_failed.emit(_current_room, inscription_key)
			return
		
		var raw_phrase = data["t"]
		if typeof(raw_phrase) != TYPE_FLOAT: # javascript always comes through as floats
			print("Inscription's phrase field failed to validate: " + str(typeof(raw_phrase)))
			death_load_failed.emit(_current_room, inscription_key)
			return
		
		var raw_word = data["w"]
		if typeof(raw_word) != TYPE_FLOAT: # javascript always comes through as floats
			print("Inscription's word field failed to validate: " + str(typeof(raw_word)))
			death_load_failed.emit(_current_room, inscription_key)
			return
			
		var pos = Vector2(raw_position[0], raw_position[1])
		
		inscription_loaded.emit(_current_room, inscription_key, pos, int(raw_phrase), int(raw_word))

# Callback for the list of valid keys for persisted inscriptions
func _receive_inscription_list(args: Variant) -> void:
	if args != null and args[0] != null and "length" in args[0]:
		print("Inscriptions Map Length: ", args[0].length)
		
		var inscription_keys: Array[String] = []
		
		for i in range(args[0].length):
			inscription_keys.push_back(args[0][i])
			
		inscriptions_updated.emit(_current_room, inscription_keys)
	else:
		print("Inscription list came back null or non-array.")


# Generate a random player name that can be used across rooms/sessions
func _random_player_name() -> String:
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	var output_string := ""

	for i in range(16):
		output_string += chars[randi() % chars.length()]

	return output_string

func _create_player_death_key(player: String, index: int) -> String:
	return "D_%s[%d]" % [player, index]

func _create_inscription_key(player: String, index: int) -> String:
	return "C_%s[%d]" % [player, index]

# Wrapper function to generate the javascript callback binding
func _bridgeToJS(cb, named_cb: String):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	# Need to hold the ref so it doesn't expire
	namedReferences[named_cb] = jsCallback
	return jsCallback
