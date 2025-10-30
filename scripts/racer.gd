extends Node3D

var haveAuthority = false
@onready var RacerSkin = $RacerSkin
@onready var RacerSprites = $RacerSkin/AnimatedSprite3D
@export var RacerItem : PackedScene
@export var RacerIcon : Texture2D

var relativeRotation : Vector3
var angleDot : float
var act_cam : Camera3D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	if not is_multiplayer_authority(): haveAuthority = false
	else : haveAuthority = true

func _ready() -> void:
	RacerSprites.frame = 0
	#position = Vector3(0.0, 0.0, 0.0)
	#rotation = Vector3(0.0, 0.0, 0.0)
	relativeRotation = Vector3(0.0, 0.0, 0.0)
	act_cam = get_viewport().get_camera_3d()

func _physics_process(_delta):
	RacerSkin.look_at(act_cam.global_position, RacerSkin.global_transform.basis.y, true)
	relativeRotation = RacerSkin.rotation_degrees
	
	var relRot_y = roundi((relativeRotation.y * 8) / 360)
	if relRot_y < 0:
		relRot_y = 8 + relRot_y
	
	angleDot = RacerSkin.global_transform.basis.y.dot(global_transform.basis.y)
	#print(str(angleDot) + " " + str(relRot_y))
	
	if angleDot < 1 and angleDot >= 0.1:
		if angleDot <= 1.0 and angleDot >= 0.8:
			match (relRot_y):
					1:
						RacerSprites.frame = 1
					2:
						RacerSprites.frame = 2
					3:
						RacerSprites.frame = 3
					4:
						RacerSprites.frame = 4
					5:
						RacerSprites.frame = 5
					6:
						RacerSprites.frame = 6
					7:
						RacerSprites.frame = 7
					_:
						RacerSprites.frame = 0
		else: if angleDot < 0.8 and angleDot >= 0.4:
			match(relRot_y):
				1:
					RacerSprites.frame = 9
				2:
					RacerSprites.frame = 10
				3:
					RacerSprites.frame = 11
				4:
					RacerSprites.frame = 12
				5:
					RacerSprites.frame = 13
				6:
					RacerSprites.frame = 14
				7:
					RacerSprites.frame = 15
				_:
					RacerSprites.frame = 8
		else:
			match(relRot_y):
				1:
					RacerSprites.frame = 17
				2:
					RacerSprites.frame = 18
				3:
					RacerSprites.frame = 19
				4:
					RacerSprites.frame = 20
				5:
					RacerSprites.frame = 21
				6:
					RacerSprites.frame = 22
				7:
					RacerSprites.frame = 23
				_:
					RacerSprites.frame = 16
	else:
			match (relRot_y):
					1:
						RacerSprites.frame = 1
					2:
						RacerSprites.frame = 2
					3:
						RacerSprites.frame = 3
					4:
						RacerSprites.frame = 4
					5:
						RacerSprites.frame = 5
					6:
						RacerSprites.frame = 6
					7:
						RacerSprites.frame = 7
					_:
						RacerSprites.frame = 0
	
	if angleDot > -0.1 and angleDot < 0.1:
		RacerSprites.frame = 24
		RacerSkin.global_rotation.y = global_rotation.y
	else : if angleDot < -0.6 and angleDot >= -1:
		RacerSprites.frame = 25
		RacerSkin.global_rotation.y = global_rotation.y

	if not haveAuthority: return
	
