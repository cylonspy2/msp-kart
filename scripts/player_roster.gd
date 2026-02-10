extends VBoxContainer

@onready var cont = $VBoxContainer

func _ready() -> void:
	HighLevelNetwork.hosted_lobby.connect(add_name)
	HighLevelNetwork.leave_lobby.connect(func(): for chilld in cont.get_children(): chilld.queue_free())
	multiplayer.peer_connected.connect(func(id) : add_name(id))
	multiplayer.peer_disconnected.connect(func(id) : lose_name(id))

func add_name(id : int):
	var trust = Label.new()
	cont.add_child(trust)
	if HighLevelNetwork.multiplayer_enabled and HighLevelNetwork.steam_active == true:
		var userID = Steam.getSteamID()
		var userInd = multiplayer.get_peers().find(id)
		print("you:%s          the girl she tells you to not worry about:%s" % [userID, userInd])
		if userInd != userID:
			#Steam.getNumLobbyMembers(SteamManager.lobby_id)
			#userID = Steam.getLobbyMemberByIndex(SteamManager.lobby_id, userInd)
			trust.text = Steam.getFriendPersonaName(id)
		else:
			trust.text = Steam.getPersonaName()
		print("Adding name to lobby roster; %s %s %s %s" % [userInd, SteamManager.lobby_id, id, Steam.getFriendPersonaName(id)])
	trust.name = str(id)

func lose_name(id : int):
	for chilld in cont.get_children():
		if chilld.name == str(id):
			chilld.queue_free()
			return
