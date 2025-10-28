extends MultiplayerSpawner

@export var parent : Node3D
@export var _spawn_Car : PackedScene
@export var _spawn_Racer : PackedScene

func _ready() -> void :
	#multiplayer.peer_connected.connect(func(id): multiplayer.spawn_player(id))
	HighLevelNetwork.despawn_player.connect(func(id): despawn_kart(id))
	pass

func spawn_player(id : int) -> void :
	if not multiplayer.is_server() : return
	
	var player: Node = spawn(_spawn_Car)
	player.name = str(id)
	
	get_node(spawn_path).call_deferred("add_child", player)
	
	player.username = HighLevelNetwork.userName
	player.Racer = _spawn_Racer
	
	var camcam : Camera3D = player.get_child(0)
	camcam.make_current()

func despawn_kart(id : int) -> void :
	if not parent.name.to_int() == id: return
	get_node(spawn_path).get_node(str(id)).queue_free()
	
