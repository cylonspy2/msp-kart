extends Node

var MAX_PLAYERS = 16
var targ_id : int

var host_mode_enabled = false

var peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()
var _hosted_lobby_id

const LOBBY_NAME = "BADDIE313"
const LOBBY_MODE = "STEAM_SERVER"

func _ready() -> void:
	#peer.lobby_created.connect(_on_lobby_created)
	pass

func retarget_server(IPA : String, PRT : int) -> void:
	targ_id = PRT

func start_dedicated_server() -> void :
	peer = SteamMultiplayerPeer.new()
	peer.lobby_created.connect(_on_lobby_created)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
	peer.create_host(0)
	host_mode_enabled = false

func become_host() -> void :
	peer = SteamMultiplayerPeer.new()
	peer.lobby_created.connect(_on_lobby_created)
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	host_mode_enabled = true

func _on_lobby_created(connect : int, lobby_id):
	if connect == 1:
		_hosted_lobby_id = lobby_id
		
		Steam.setLobbyJoinable(_hosted_lobby_id, true)
		
		Steam.setLobbyData(_hosted_lobby_id, "name", LOBBY_NAME)
		Steam.setLobbyData(_hosted_lobby_id, "mode", LOBBY_MODE)
		Steam.setLobbyData(_hosted_lobby_id, "player cap", MAX_PLAYERS)

func become_client(id : int) -> void :
	peer = SteamMultiplayerPeer.new()
	targ_id = id
	peer.connect_lobby(targ_id)
	multiplayer.multiplayer_peer = peer

func list_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.requestLobbyList()
