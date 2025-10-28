extends Node3D

var haveAuthority = false
@export var RacerSkin : Node
@export var RacerItem : PackedScene

var relativeRotation : Vector3

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	if not is_multiplayer_authority(): haveAuthority = false
	else : haveAuthority = true

func _ready() -> void:
	position = Vector3(0.0, 0.0, 0.0)
	rotation = Vector3(0.0, 0.0, 0.0)
	relativeRotation = Vector3(0.0, 0.0, 0.0)

func _physics_process(_delta):
	RacerSkin.global_transform.look_at(get_viewport().get_camera_3d().global_position)
	relativeRotation = RacerSkin.rotation
	
	if not haveAuthority: return
	
