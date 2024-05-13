extends Node

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
signal death_loaded(room_name: String, player_name: String, location: Vector2, consumed: bool)
signal inscription_loaded(room_name: String, player_name: String, location: Vector2, type: int, likes: int)

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

# Need to use their room codes, not just any values we want
# More can be generated by not specifying a room code.
# Printed out on connect in the console log of web browser
const GLOBAL_ROOMS = [
	"PER_4EP6RJFD4METR6ALBQFEGH43HP",
]

# Room Code of the current room we are connected to
var _current_room: String = ""

# Check if the player has entered their name
# Into the room's global username lookup list (they should only do it once)
# String (room name) -> bool (inserted into index)
var _created_death_tracker: Dictionary = {}
var _created_comment_tracker: Dictionary= {}

# Generated at startup
# This will be a persistent ID the player uses across all rooms
var _my_user_id = ""

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
	
	# TODO: Add retry logic if the first room is full,
	#  fallback to the next and so on
	connect_room(GLOBAL_ROOMS[0])
 
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
		_bridgeToJS(_on_insert_coin),
		_bridgeToJS(_on_disconnected)
	)

# Update the player's position so others can see them
func update_my_pos(pos: Vector2) -> void:
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
	
	return Vector2(parsed.data[0], parsed.data[1])

 
# Request the list of deaths in the current room we are connected to
# This will get the list of all playernames with deaths
# and the start the individual requests for each playername death info
func request_death_list() -> void:
	# TODO: break this into parts by zone
	_playroom.getPersistentData("deaths") \
		.then(_bridgeToJS(_receive_death_list))


# Request the list of inscriptions in the current room we are connected to
# This will get the list of all playernames with inscriptions
# and the start the individual requests for each playername inscription info
func request_inscriptions_list() -> void:
	# TODO: break this into parts by zone
	_playroom.getPersistentData("inscriptions") \
		.then(_bridgeToJS(_receive_inscription_list))


# Register where the player died
# And include some of their footprints up to the point they died
func add_death_location(position: Vector2, footprints: Array[Vector2]) -> void:
	# TODO: Shard the death tracker by zone since we cant change rooms
	if not _created_death_tracker.has(_current_room):
		_created_death_tracker[_current_room] = true
		var key = "deaths"
		
		# Add the player's ID into the death track 
		# so other players know the key exists
		await _playroom.insertPersistentData(
			key,
			_my_user_id
		)
	
	var trail: Array[Array] = []
	for v in footprints:
		trail.append([v.x, v.y])
	
	_playroom.setPersistentData(
		"deaths_" + _my_user_id,
		JSON.stringify({
			"p": [position.x, position.y],
			"f": trail
		})
	)

# Called when the player has connected to a room successfully
func _on_insert_coin(args: Variant):
	print("Joined room successfully: ", _current_room, " Args: ", args)
	print("Room claims to be: ", _playroom.getRoomCode())
	_current_room = _playroom.getRoomCode()
	server_connected.emit(_current_room)
	
	# Start with fresh room player tracking on new connections
	_tracked_room_players[_current_room] = {}
	
	# Attach the callback to get information when players join
	_playroom.onPlayerJoin(_bridgeToJS(_on_player_join))
	
	request_death_list()
	
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
		_on_player_quit.bind(_current_room, player_name)
	))
	
	# Send out that the player joined
	player_joined.emit(_current_room, player_name)

# Called when a player quits
func _on_player_quit(room_name, player_name: String, args: Variant) -> void:
	print("[Playroom] Player quit the room: ", room_name, " Player: ", player_name)
	player_left.emit(room_name, player_name)


# Callback for the list of valid keys we can use for the persisted deaths
func _receive_death_list(args: Variant) -> void:
	if "length" in args[0]:
		print("Death Map Length: ", args[0].length)
		deaths_updated.emit(args[0])


# Callback for the list of valid keys for persisted inscriptions
func _receive_inscription_list(args: Variant) -> void:
	if "length" in args[0]:
		print("Inscriptions Map Length: ", args[0].length)
		inscriptions_updated.emit(args[0])


# Generate a random player name that can be used across rooms/sessions
func _random_player_name() -> String:
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	var output_string := ""

	for i in range(16):
		output_string += chars[randi() % chars.length()]

	return output_string


# Wrapper function to generate the javascript callback binding
func _bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	# Need to hold the ref so it doesn't expire
	# TODO: Garbage collection will be needed for ones that arent needed anymore
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback
