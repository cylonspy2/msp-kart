extends Node

var LOBBY_NAME = "DEDICATED_SERVER"
var MAX_PLAYERS = 16
var targ_id : int

var host_mode_enabled = false

var peer : SteamMultiplayerPeer = SteamMultiplayerPeer.new()
var _hosted_lobby_id

const LOBBY_MODE = "STEAM_SERVER"

func _ready() -> void:
	#peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_created.connect(_on_lobby_created.bind())
	HighLevelNetwork.leave_lobby.connect(leave_lobby)
	pass

func retarget_server(_IPA : String, PRT : int) -> void:
	targ_id = PRT

func start_dedicated_server() -> void :
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	match(HighLevelNetwork.STEAM_LOBBY_TYPE):
		0:
			Steam.createLobby(Steam.LOBBY_TYPE_PRIVATE, MAX_PLAYERS)
		1:
			Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_PLAYERS)
		2:
			Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
	host_mode_enabled = false

func become_host() -> void :
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	LOBBY_NAME = HighLevelNetwork.lobbyName
	MAX_PLAYERS = HighLevelNetwork.MAX_PLAYERS
	match(HighLevelNetwork.STEAM_LOBBY_TYPE):
		0:
			Steam.createLobby(Steam.LOBBY_TYPE_PRIVATE, MAX_PLAYERS)
		1:
			Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_PLAYERS)
		2:
			Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
	host_mode_enabled = true

func _on_lobby_created(connectt : int, lobby_id):
	if connectt == 1:
		_hosted_lobby_id = lobby_id
		SteamManager.lobby_id = lobby_id
		
		Steam.setLobbyJoinable(_hosted_lobby_id, true)
		
		Steam.setLobbyData(_hosted_lobby_id, "name", LOBBY_NAME)
		Steam.setLobbyData(_hosted_lobby_id, "mode", LOBBY_MODE)
		Steam.setLobbyData(_hosted_lobby_id, "player cap", str(MAX_PLAYERS))
		Steam.setLobbyData(_hosted_lobby_id, "has password", str(HighLevelNetwork.passwordReq))
		Steam.setLobbyData(_hosted_lobby_id, "password", HighLevelNetwork.pwrd)
		
		print("set lobby at: " + str(_hosted_lobby_id))
		
		var set_relay : bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to act as P2P fallback... %s" % set_relay)
		
		_create_host(Steam.getLobbyOwner(_hosted_lobby_id))

func _create_host(id : int = 0):
	#peer = SteamMultiplayerPeer.new()
	var error = peer.create_host(0)
	if error == OK:
		if not OS.has_feature("dedicated_server"):
			print("Hosting Lobby")
			multiplayer.set_multiplayer_peer(peer)
			HighLevelNetwork.hosted_lobby.emit(id)
	else:
		print("error creating host: %s" % error)

func become_client(id : int) -> void :
	targ_id = id
	
	#peer = SteamMultiplayerPeer.new()
	#var error = peer.create_client(0)
	if true:
		
		if not Steam.lobby_joined.is_connected(_on_lobby_joined.bind()):
			Steam.lobby_joined.connect(_on_lobby_joined.bind())
		
		SteamManager.lobby_members.clear()
		
		Steam.joinLobby(targ_id)
		
		#multiplayer.set_multiplayer_peer(peer)
		
		#print(error)
	else:
		#print("error creating client: %s" % error)
		pass

func _on_lobby_joined(lobby_id : int, _permissions : int, _locked : bool, response : int):
	print("joined lobby with ID %s" % str(lobby_id))
	
	#HighLevelNetwork.hosted_lobby.emit()
	print(response)
	if response == 1:
		
		_hosted_lobby_id = lobby_id
		SteamManager.lobby_id = lobby_id
		
		SteamManager.get_lobby_members()
		
		SteamManager.make_P2P_handshake()
		
		var id = Steam.getLobbyOwner(lobby_id)
		if id != Steam.getSteamID():
			print("connecting client to socket...")
			connect_socket(id)
		else:
			print("I am the host, hehehe")
	else:
		var FAIL_REASON : String
		match(response):
			2: FAIL_REASON = "This lobby no longer exists"
			3: FAIL_REASON = "You lack permission to join this lobby"
			4: FAIL_REASON = "The lobby is full"
			5: FAIL_REASON = "Uh... Huh. I got nothing. *Something* broke..."
			6: FAIL_REASON = "Wow, you're banned! What did you *do*, lol"
			7: FAIL_REASON = "You can't join, your account is \"limited\", whever that means"
			8: FAIL_REASON = "This lobby is locked or disabled"
			9: FAIL_REASON = "This lobby is community locked"
			10: FAIL_REASON = "Someone in there blocked you, so I'm just gonna. Not."
			11: FAIL_REASON = "Nah fam, you don't wanna be in there. A user you blocked is in there."
		print(FAIL_REASON)

func connect_socket(steam_id : int):
	var error = peer.create_client(steam_id, 0)
	if error == OK:
		print("connecting peer to host...")
		multiplayer.set_multiplayer_peer(peer)
		HighLevelNetwork.lobbyName = Steam.getLobbyData(steam_id, "name")
		HighLevelNetwork.entered_lobby.emit(steam_id)
	else:
		print("Error creating client: %s" % str(error))

func list_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	if HighLevelNetwork.lobby_search != "":
		Steam.addRequestLobbyListStringFilter("name", HighLevelNetwork.lobby_search, Steam.LOBBY_COMPARISON_EQUAL)
	else:
		Steam.addRequestLobbyListStringFilter("name", HighLevelNetwork.lobby_search, Steam.LOBBY_COMPARISON_EQUAL_TO_GREATER_THAN)
	Steam.requestLobbyList()

func leave_lobby():
	Steam.lobby_joined.disconnect(_on_lobby_joined.bind())
	peer.close()
	peer.clear_all_configs()
	peer = SteamMultiplayerPeer.new()

func get_client_target() -> int:
	return _hosted_lobby_id
