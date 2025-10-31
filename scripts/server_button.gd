extends Control

@export var LOBBYNAME : String = "test_host"
@export var IPNAME : String = "localhost"
@export var PORTNAME : int = 42168

var networkBrain : Node

func _ready():
	HighLevelNetwork.enter_lobby.connect(_trigger_lobby)

func _setupInfo(nam : String, IPa : String, por : int, playCount : int, NetworkManager : Node) -> void:
	networkBrain = NetworkManager
	LOBBYNAME = nam
	IPNAME = IPa
	PORTNAME = por
	if NetworkManager.network_is_steam:
		pass
	$HBoxContainer/name.text = LOBBYNAME
	$HBoxContainer/IP_address.text = IPNAME
	$HBoxContainer/player_count.text = str(playCount)

func _trigger_lobby(lobby_id = 0) -> void :
	print("going to " + LOBBYNAME)
	networkBrain.retarget_server(IPNAME, PORTNAME)
	networkBrain.become_client(lobby_id)

func _on_button_pressed() -> void:
	if networkBrain.network_is_steam:
		HighLevelNetwork.enter_lobby.emit(PORTNAME)
	else:
		HighLevelNetwork.enter_lobby.emit()
