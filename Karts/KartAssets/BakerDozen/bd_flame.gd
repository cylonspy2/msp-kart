extends Node3D

@onready var Parent = %ControlSynchronizer
@export var Ball : RigidBody3D
@export var processMat : ParticleProcessMaterial

var partX : float

func _ready() -> void:
	partX = 0.0

func _physics_process(_delta) -> void:
	partX = lerp(partX, -Parent.inputRot, _delta * 10)
	var BallVel = clamp(Ball.linear_velocity.length() * signf(Parent.inputDir), -0.1, 10.0)
	processMat.direction =  Vector3(0.5 * partX * BallVel, 0.0, BallVel).normalized() #+ Vector3(partX, 0.0, 0.0).normalized()
	processMat.initial_velocity_min = Ball.linear_velocity.length() * -0.1
	processMat.initial_velocity_max = Ball.linear_velocity.length() * -0.1
	#processMat.linear_accel_min = Ball.linear_velocity.length() * 1
	#processMat.linear_accel_max = Ball.linear_velocity.length() * 1
	#print(str(partX))
