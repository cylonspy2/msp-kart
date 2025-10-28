extends MultiplayerSpawner

@export var CarParent : Node3D

func _ready() -> void:
	CarParent.fireItem.connect(func(id) : _spawn_item(false, id))
	CarParent.altFireItem.connect(func(id) : _spawn_item(true, id))
	pass

func _spawn_item(altFired : bool, item : PackedScene):
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		if altFired:
			var itemn: Node = spawn(item)
			itemn.name = str(CarParent.player_id)
			itemn.define_caster(CarParent)
			get_node(spawn_path).call_deferred("add_child", itemn)
			itemn.cast_item()
		else:
			var itemn: Node = spawn(item)
			itemn.name = str(CarParent.player_id)
			itemn.define_caster(CarParent)
			get_node(spawn_path).call_deferred("add_child", itemn)
			itemn.cast_item()
		pass
	pass
