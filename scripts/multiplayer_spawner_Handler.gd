extends MultiplayerSpawner

@export var networkPlayer : PackedScene

func _ready() -> void :
	multiplayer.peer_connected.connect(func(id): spawn_player(id))
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))

func despawn_player(id :int) -> void:
	if not multiplayer.is_server() || OS.has_feature("dedicated_server") : return
	
	get_node(spawn_path).get_node(str(id)).queue_free()
	pass

func spawn_player(id : int) -> void :
	if not multiplayer.is_server() || OS.has_feature("dedicated_server") : return
	
	var player: Node = networkPlayer.instantiate()
	player.name = str(id)
	
	get_node(spawn_path).call_deferred("add_child", player)
	
	##already handled by the SpectatorMaster script
	#if player.name == str(multiplayer.get_unique_id()): 
		#var camcam : Camera3D = player.get_child(0)
		#camcam.make_current()
