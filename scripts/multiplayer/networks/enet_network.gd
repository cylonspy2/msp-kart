extends Node

var MAX_PLAYERS = 16
var IP_ADDRESS : String = "localhost"
var PORT : int = 42168

var host_mode_enabled = false

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

const LOBBY_NAME = "BADDIE313"
const LOBBY_MODE = "COOP"

func retarget_server(IPA : String, PRT : int) -> void:
	PORT = PRT
	IP_ADDRESS = IPA

func start_dedicated_server() -> void :
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	host_mode_enabled = false

func become_host() -> void :
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	host_mode_enabled = true

func become_client(id : int) -> void :
	peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func list_lobbies():
	pass
