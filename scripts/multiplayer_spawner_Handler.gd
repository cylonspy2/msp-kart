extends MultiplayerSpawner

@export var networkPlayer : PackedScene
@export var racerSpawnpath : Node3D
@export var SpectatorSpawnpath : NodePath
@export var trackSlot : Node3D
@export var spawnedTrack : Node3D

func _ready() -> void :
	HighLevelNetwork.hosted_lobby.connect(func(id): spawn_player(id))
	multiplayer.peer_connected.connect(func(id): spawn_player(id))
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))
	HighLevelNetwork.leave_lobby.connect(_shut_it_down)

func despawn_player(id :int) -> void:
	#if not multiplayer.is_server() || OS.has_feature("dedicated_server") : return
	
	get_node(SpectatorSpawnpath).get_node(str(id)).queue_free()
	pass

func spawn_player(id : int) -> void :
	#if not multiplayer.is_server() || OS.has_feature("dedicated_server") : return
	
	var player: Node = networkPlayer.instantiate()
	player.name = str(id)
	
	get_node(SpectatorSpawnpath).call_deferred("add_child", player)
	
	##already handled by the SpectatorMaster script
	#if player.name == str(multiplayer.get_unique_id()): 
		#var camcam : Camera3D = player.get_child(0)
		#camcam.make_current()

func spawn_level(track : PackedScene):
	var trac: Node = track.instantiate()
	
	trackSlot.add_child(trac)
	
	spawnedTrack = trac
	racerSpawnpath = trac.Car_Root[0]
	#print(racerSpawnpath)

func _shut_it_down():
	var specPath = get_node(SpectatorSpawnpath)
	for viewer in specPath.get_children(false):
		viewer.queue_free()
