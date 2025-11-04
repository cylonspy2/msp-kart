extends VBoxContainer

@onready var cont = $VBoxContainer

func _ready() -> void:
	HighLevelNetwork.hosted_lobby.connect(add_name)
	multiplayer.peer_connected.connect(func(id) : add_name(id))
	multiplayer.peer_disconnected.connect(func(id) : lose_name(id))

func add_name(id : int = 0):
	var trust = Label.new()
	cont.add_child(trust)
	if HighLevelNetwork.multiplayer_enabled and HighLevelNetwork.steam_active == true:
		var userID = Steam.getSteamID()
		if id > -1:
			userID = Steam.getLobbyMemberByIndex(SteamManager.lobby_id, id)
		trust.text = Steam.getFriendPersonaName(userID)
		#print("%s %s %s %s" % [userID, SteamManager.lobby_id, id, Steam.getFriendPersonaName(userID)])
	trust.name = str(id)

func lose_name(id : int):
	for chilld in cont.get_children():
		if chilld.name == str(id):
			chilld.queue_free()
			return
