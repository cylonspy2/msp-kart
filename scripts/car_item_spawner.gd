extends MultiplayerSpawner

@export var CarParent : Node3D
@export var racerAltItem : PackedScene = PackedScene.new()
@export var Item : PackedScene = PackedScene.new()

func _ready() -> void:
	#CarParent.fireItem.connect(_spawn_item(false))
	#CarParent.altFireItem.connect(_spawn_item(true))
	pass

func _spawn_item(altFired : bool):
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		if altFired:
			var itemn: Node = spawn(racerAltItem)
			itemn.name = str(CarParent.player_id)
			itemn.define_caster(CarParent)
			get_node(spawn_path).call_deferred("add_child", itemn)
		else:
			var itemn: Node = spawn(Item)
			itemn.name = str(CarParent.player_id)
			itemn.define_caster(CarParent)
			get_node(spawn_path).call_deferred("add_child", itemn)
		pass
	pass
