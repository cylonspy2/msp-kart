extends Node

var is_owned: bool = false
var steam_app_id: int = 4178390   #480
var steam_depot_id: int = 4178391
var steam_id: int = 0
var steam_username: String = ""

var lobby_id = 0
var lobby_max_members = 4

var lobby_members: Array = []

func _init():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _ready() -> void:
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Steam Initialized? %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Steam Initialization failed. Shutting Down. %s " % initialize_response)
		get_tree().quit()
		return
	
	
	
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	print("steam id: %s" % steam_id)
	print("steam username: %s" % steam_username)
	
	if is_owned == false:
		print("You didn't download this from Steam, did you.")
	

func get_lobby_members():
	
	lobby_members.clear()
	
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for this_member in range(0, num_of_members):
		var member_steam_id : int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name : String = Steam.getFriendPersonaName(member_steam_id)
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})
		pass
	
	print("checking lobby count")
	print(lobby_members.size())
	
	return


func _on_lobby_chat_update(this_lobby_id:int, change_id:int, making_change_id:int, chat_state:int):
	
	var changer_name : String = Steam.getFriendPersonaName(change_id)
	
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby" % changer_name)
	
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby" % changer_name)
	
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s was kicked" % changer_name)
	
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s was banned" % changer_name)
	
	else:
		print("%s did... something" % changer_name)
	
	get_lobby_members()
	
	#HighLevelNetwork.update_lobby_data.emit(Steam.getLobbyData(this_lobby_id, "name"))

func make_P2P_handshake():
	print("sending P2P Handshake to lobby")
	
	#send_p2p_packet(0, {"message": "handshake", "from": steam_id})
	
	
	
	
	
	
	
	
	
