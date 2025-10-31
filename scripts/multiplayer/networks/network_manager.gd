extends Node

enum MULTIPLAYER_NETWORK_TYPE {ENET, STEAM}
@export var network_is_steam : bool =  true

@export var _players_spawn_node : Node3D

var active_network_type: MULTIPLAYER_NETWORK_TYPE = MULTIPLAYER_NETWORK_TYPE.STEAM
var enet_network_scene := preload("res://scenes/multiplayer/networks/enet_network.tscn")
var steam_network_scene := preload("res://scenes/multiplayer/networks/steam_network.tscn")
var active_network

var is_host : bool
var targ_id : int

func _ready() -> void:
	is_host = false

func _build_multiplayer_network():
	if not active_network:
		print("setting active lobby")
		
		HighLevelNetwork.multiplayer_enabled = true
		
		match active_network_type:
			MULTIPLAYER_NETWORK_TYPE.ENET:
				print("Setting network type to eNet")
				network_is_steam = false
				_set_active_network(enet_network_scene)
			MULTIPLAYER_NETWORK_TYPE.STEAM:
				print("Setting network type to Steam")
				network_is_steam = true
				_set_active_network(steam_network_scene)
			_:
				print("no matching network type!")

func _set_active_network(active_network_scene):
	var network_scene_initialized = active_network_scene.instantiate()
	active_network = network_scene_initialized
	#active_network._players_spawn_node = _players_spawn_node
	add_child(active_network)

func retarget_server(NAME: String, PORT : int):
	active_network.retarget_server(NAME, PORT)

func start_dedicated_server():
	_build_multiplayer_network()
	HighLevelNetwork.host_mode_enabled = false
	active_network.start_dedicated_server()
	is_host = true

func become_host():
	_build_multiplayer_network()
	HighLevelNetwork.host_mode_enabled = true
	active_network.become_host()
	is_host = true

func become_client(lobby_id = 0):
	_build_multiplayer_network()
	active_network.become_client(lobby_id)

func list_lobbies():
	_build_multiplayer_network()
	active_network.list_lobbies()
