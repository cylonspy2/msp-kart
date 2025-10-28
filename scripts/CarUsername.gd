extends Node3D

@onready var CarParent = $"../../.."

func _ready() -> void:
	if not HighLevelNetwork.multiplayer_enabled:
		visible = false
		return
	if %ControlSynchronizer.get_multiplayer_authority() != CarParent.player_id: 
		visible = false

func _process(delta: float) -> void:
	if visible:
		look_at(get_viewport().get_camera_3d().global_position)
