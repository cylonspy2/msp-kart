extends MultiplayerSpawner

@export var networkPlayer : PackedScene
@export var racerSpawnpath : NodePath
@export var SpectatorSpawnpath : NodePath
@onready var trackSlot = $"../RaceSlot"
@export var spawnedTrack : Node3D

func _ready() -> void :
	multiplayer.peer_connected.connect(func(id): spawn_player(id))
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))

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
	
	get_node(SpectatorSpawnpath).call_deferred("add_child", trac)
	
	spawnedTrack = trac
	racerSpawnpath = trac.Car_Root[0].get_parent()
