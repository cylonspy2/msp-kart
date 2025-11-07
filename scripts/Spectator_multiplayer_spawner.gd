extends MultiplayerSpawner

@export var parent : Node3D
@export var _spawn_Car : PackedScene
@export var _spawn_Racer : PackedScene

func _ready() -> void :
	multiplayer.peer_connected.connect(func(id, spawn_path): multiplayer.spawn_kart(id, spawn_path))
	HighLevelNetwork.despawn_player.connect(func(id): despawn_kart(id))
	HighLevelNetwork.spawn_racers.connect(func(id, patth): spawn_kart(id, patth))
	pass

func spawn_kart(id : int, spawnpath : NodePath) -> void :
	#if not multiplayer.is_server() : return
	if not parent.name.to_int() == id: return
	
	var spawnpathNodes : Array[NodePath] 
	
	for baka : Node in get_node(spawnpath).get_children(false):
		var truf = baka.get_path()
		spawnpathNodes.append(truf)
	
	var chosenSlot = clamp(parent.name.to_int(), 0, spawnpathNodes.size())
	spawn_path = spawnpathNodes[chosenSlot]
	
	var player: Node = spawn(_spawn_Car)
	player.name = str(parent.name)
	
	get_node(spawn_path).call_deferred("add_child", player)
	
	player.username = HighLevelNetwork.userName
	player.Racer = _spawn_Racer
	
	var camcam : Camera3D = player.get_child(2).get_child(0).get_child(0)
	camcam.make_current()

func despawn_kart(id : int) -> void :
	if not parent.name.to_int() == id: return
	get_node(spawn_path).get_node(str(id)).queue_free()
	
