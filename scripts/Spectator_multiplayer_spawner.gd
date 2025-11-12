extends MultiplayerSpawner

@export var parent : Node3D
@export var _spawn_Car : PackedScene
@export var _spawn_Racer : PackedScene

func _ready() -> void :
	print("Spectator %s set up" % parent.name)
	#multiplayer.peer_connected.connect(func(id, spawn_path): multiplayer.spawn_kart(id, spawn_path))
	HighLevelNetwork.despawn_player.connect(func(id): despawn_kart(id))
	HighLevelNetwork.spawn_racers.connect(func(id, patth): spawn_kart(id, patth))
	pass

func spawn_kart(ind : int, kartpath : Node3D) -> void :
	#if not multiplayer.is_server() : return
	
	#var indt : int = 0
	#var StemCnt = Steam.getNumLobbyMembers(SteamManager.lobby_id)
	#while indt < StemCnt:
		#if parent.name.to_int() == Steam.getLobbyMemberByIndex(SteamManager.lobby_id, indt):
			#return
		#indt += 1
	##set_multiplayer_authority(multiplayer.get_peers()[indt])
	#print(indt)
	#print(get_multiplayer_authority())
	
	#var peer_ind = multiplayer.get_peers().find(ind)
	Steam.getNumLobbyMembers(SteamManager.lobby_id)
	var id = Steam.getLobbyMemberByIndex(SteamManager.lobby_id, ind-1)
	var userID = Steam.getFriendPersonaName(id)
	#print ("Spawning Kart from %s, if it matches user %s %s %s" % [parent.name, id, userID, peer_ind])
	if not parent.name.to_int() == id: return
	
	set_multiplayer_authority(multiplayer.get_unique_id())
	
	var spawnpathNodes : Array[Node3D] 
	
	#print(kartpath)
	
	for baka : Node3D in kartpath.get_children(false):
		var truf = baka
		spawnpathNodes.append(truf)
	
	var chosenSlot = wrapi(parent.name.to_int(), 1, spawnpathNodes.size()-1)
	spawn_path = get_path_to(spawnpathNodes[chosenSlot], true)
	#print(spawn_path)
	
	#print(str(get_multiplayer_authority()) + " " + str(parent.name.to_int()))
	
	if not is_inside_tree():
		print("not in tree")
	else: if not multiplayer.has_multiplayer_peer():
		print("no peer")
	else: if not is_multiplayer_authority():
		print("not authority")
	var player: Node3D = _spawn_Car.instantiate()
	player.name = str(parent.name)
	
	spawnpathNodes[chosenSlot].call_deferred("add_child", player)
	#get_node(spawn_path).call_deferred("add_child", player)
	if HighLevelNetwork.steam_active:
		player.username = userID
	else:
		player.username = HighLevelNetwork.userName
	player.Racer = _spawn_Racer
	
	#var track = kartpath.get_parent()
	#track.Cars.append(player)
	
	var camcam : Camera3D = player.get_child(2).get_child(0).get_child(0)
	camcam.make_current()
	HighLevelNetwork.attach_icon.emit(player)

func despawn_kart(id : int) -> void :
	if not parent.name.to_int() == id: return
	get_node(spawn_path).get_node(str(id)).queue_free()
	
