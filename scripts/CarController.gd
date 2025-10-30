extends Node3D

@export var username : String

@export var Racer : PackedScene

@export var hasItem = false
@export var itemHeld : PackedScene = null
@export var altItem : PackedScene = null

@export_group("Leaderboard Data")
@export var leaderboard_placement : int = 0
@export var laps_made : int = 0
@export var track_pos : float = 0.0
@export var crossed_checkpoints : Array[Node3D]

@onready var MS = $CarParent_Logic/ControlSynchronizer
@onready var UI = $Car/CarLogic/Camera/Car_UI
@onready var RacerSpawnLoc = $Car/ModelParent/RacerSpawn
@onready var ItemSpawner = $Items/ItemSpawner
@onready var Ball = $Ball
@onready var BallCollisionShape = $Ball/CollisionShape3D
@onready var driftTimer = $CarParent_Logic/driftTimer
@onready var boostTimer = $CarParent_Logic/boostTimer
@onready var Anim = $CarParent_Logic/AnimationPlayer
@onready var camAnim = $CarParent_Logic/CamAnimationPlayer
@onready var groundRay1 = $Car/CarLogic/RayCast3D1
@onready var groundRay2 = $Car/CarLogic/RayCast3D2
@onready var groundRay3 = $Car/CarLogic/RayCast3D3
@onready var groundRay4 = $Car/CarLogic/RayCast3D4
@onready var CarHitBox = $Car/CarLogic/CarHitbox
@export_group("Car Model Data")
@export var Car = Node3D
@export var RightWheel = MeshInstance3D
@export var LeftWheel = MeshInstance3D
@export var CarBody = MeshInstance3D
@export var CarModel = MeshInstance3D
@export var ModelOffset = Vector3(0.0, -0.5, 0.0)

@export_group("Car Stats")
@export var maxSpeed = 100.0
@export var hurtSpeed = 100.0
@export var acceleration = 70.0
@export var steering = 12.0
@export var steeringDrift = 0.55
@export var steeringAccelMod = 0.8
@export var turnspeed = 5.0
@export var weight = 10.0
@export var driftBoost = 1.75
@export var airControl = 0.1

var speedInput = 0.0
var rotateInput = 0.0
var minimumDriftRotation = 2.0
var gravForce = Vector3(0.0, -1.0, 0.0)
var correctivey = 0.0
@export_group("Car Visual Tweaks")
@export var bodytilt = 30.0
@export var maxCarTwist = 30.0
@export var carTwistRate = 5.0
var carTwist = 0.0
var faceForce = Vector3(0.0, 0.0, 1.0)
@export_group("Car Drift Data")
@export var drifting = false
@export var startedDrifting = false
@export var driftDirection = 0
var startDriftDirection = 0
var minimumDrift = false
var boost = 1

@export var boostTiering = 0
var maxBoostTier = 4
var turnable = false
var prevForce = Vector3(0.0, 0.0, 0.0)

var haveAuthority = false

signal fireItem(item : PackedScene)
signal altFireItem(item : PackedScene)
signal gainItem(item : PackedScene)

@export_group("Server Data")
@export var velocity_smooth = 2.0
@export var angular_smooth = 3.64
@export var start_drift = false
@export var end_drift = false
@export var firedItem = false
@export var altFiredItem = false
@export var server_Pos : Vector3
@export var server_Rot : Basis
@export var server_Pos_Offset : Vector3
@export var time_since_last_update : float

var gravDir : Vector3
var hurtAccel : float

@export var player_id := 1:
	set(id):
		player_id = id
		%ControlSynchronizer.set_multiplayer_authority(id)

func _enter_tree():
	fireItem.connect(ThrowItem)
	altFireItem.connect(TriggerRacerAbility)
	gainItem.connect(func(id) : PickupItem(id))

func _ready():
	$Car/CarLogic/CarHitbox.name = str(player_id)
	
	if Racer != null:
		SpawnRacer(Racer)
	else:
		print("ERROR, ERROR, YOU LACK A RACER")
	
	if %ControlSynchronizer.get_multiplayer_authority() != player_id: 
		haveAuthority = false
		#$Car/CarLogic/Camera.enabled = false
	else : 
		haveAuthority = true
		#$Car/CarLogic/Camera.make_current()
	
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))
	
	groundRay1.add_exception(Ball)
	groundRay2.add_exception(Ball)
	groundRay3.add_exception(Ball)
	groundRay4.add_exception(Ball)
	
	hurtAccel = acceleration

func _physics_process(_delta):
	
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		time_since_last_update += _delta
	else:
		server_Pos_Offset = Vector3()
		time_since_last_update = 0.0
	
	Car.transform.origin = Car.transform.origin.move_toward(Ball.transform.origin + ModelOffset, velocity_smooth)
	Ball.transform.origin = Ball.transform.origin.move_toward(Car.transform.origin - ModelOffset, velocity_smooth)
	
	var forceForce = (Car.global_transform.basis.z * speedInput)
	
	gravDir = gravForce * 9.810 * weight
	var hitr = Ball.move_and_collide(gravDir * _delta, true)
	if not hitr:
		forceForce *= airControl
	
	if drifting :
		var lerpForce = lerp(((forceForce * boost) * steeringAccelMod), prevForce, clamp(prevForce.length(), 0.0, 1.0) * _delta)
		
		var hitS = CarHitBox.move_and_collide(lerpForce * _delta, true)
		if hitS:
			pass
		else:
			pass
		
		Ball.apply_central_force((lerpForce))
		prevForce = lerpForce
	else :
		var lerpForce = lerp(((forceForce * boost)), prevForce, clamp(prevForce.length(), 0.0, 1.0) * _delta)
		
		var hitS = CarHitBox.move_and_collide(lerpForce * _delta, true)
		if hitS:
			pass
		else:
			pass
		
		Ball.apply_central_force(lerpForce)
		prevForce = lerpForce
	
	hitr = Ball.move_and_collide(gravDir * _delta, true)
	if hitr:
		Ball.gravity_scale = 0.0
		var avgHitPos = Vector3(0.0, 0.0, 0.0)
		var b = 0
		while b < hitr.get_collision_count():
			avgHitPos += hitr.get_position(b)
			b += 1
		avgHitPos /= b
		var newGrav = (-(Ball.global_position - avgHitPos)).normalized()
		gravForce = lerp(gravForce, newGrav, clamp(_delta * 20 * rad_to_deg(gravForce.dot(newGrav)), 0.0, 1.0))
		notify_property_list_changed()
	else:
		Ball.gravity_scale = 3.0
		forceForce *= 0
		gravForce = Vector3(0.0, -1.0, 0.0)
		notify_property_list_changed()
		Ball.apply_central_force(gravForce * 9.81 * weight)
	gravDir = gravForce * weight
	Ball.move_and_collide(gravDir * _delta)
	
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		server_Pos_Offset += Ball.global_position - server_Pos
		Ball.global_position.slerp(server_Pos + server_Pos_Offset, clamp(1 - time_since_last_update, 0, 1))
		Car.global_transform.basis.slerp(server_Rot, clamp(1 - (time_since_last_update * 1000), 0, 1))
	else:
		server_Pos = Ball.global_position
		server_Rot = Car.global_transform.basis
	
	#print(Ball.angular_velocity.length())

func _process(delta):
	speedInput = (MS.inputDir) * acceleration
	rotateInput = deg_to_rad(steering) * (MS.inputRot) ## * (Ball.linear_velocity.length() / maxSpeed)
	
	var hiter = Ball.move_and_collide(gravDir * delta, true)
	if not hiter:
		rotateInput *= airControl
	
	RightWheel.rotation.y = lerp(RightWheel.rotation.y, rotateInput, 5 * delta)
	LeftWheel.rotation.y = lerp(LeftWheel.rotation.y, rotateInput, 5 * delta)
	
	#if not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled: 
		###Only do the bare necessity to figure out what animations to play
		#if start_drift and not drifting and rotateInput != 0 and speedInput > 0:
			#if rotateInput > 0:
				#Anim.play("Hop")
			#else: if rotateInput < 0:
				#Anim.play("HopRight")
			#else:
				#Anim.play("HopCenter")
		#
		#return
	
	if multiplayer.is_server() or not HighLevelNetwork.multiplayer_enabled: 
		## serverwork
		pass
	
	if haveAuthority:
		$Car/CarLogic/UsernameHolder/Username.text = username
	
	if firedItem && itemHeld != null:
		fireItem.emit(itemHeld)
		itemHeld = null
		firedItem = false
	if altFiredItem && altItem != null:
		altFireItem.emit(altItem)
		altFiredItem = false
	
	if start_drift and not drifting and rotateInput != 0 and speedInput > 0:
		boostTiering = 0
		startDriftDirection = MS.inputRot
		carTwist = deg_to_rad(maxCarTwist * startDriftDirection)
		startedDrifting = true
		StartDrift()
		start_drift = false
	
	if drifting:
		var driftAmount = 0.0
		driftAmount += startDriftDirection
		driftAmount *= deg_to_rad(steering * steeringDrift)
		rotateInput += driftDirection + driftAmount
	
	if drifting and (end_drift or speedInput < 1):
		startedDrifting = false
		StopDrift()
		end_drift = false
	
	if Ball.linear_velocity.length() > 0.75 :
		turnable = true
	else:
		turnable = false
	RotateCar(delta)
	
	
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		pass

func RotateCar(delta):
	var antiGrav = -gravForce
	var rotari = rotateInput
	
	var carBasis = Car.global_transform.basis.orthonormalized()
	if not turnable :
		rotari = 0.0
	var newBasis = Car.transform.basis.rotated(Car.transform.basis.y, rotari)
	Car.transform.basis = Car.transform.basis.slerp(newBasis, turnspeed * delta)
	Car.transform.basis = Car.transform.basis.orthonormalized()
	carBasis = Car.global_transform.basis.orthonormalized()
	
	if Vector3(0.0, 1.0, 0.0) != antiGrav:
		#var gravCross = antiGrav.cross(Vector3(0.0, 1.0, 0.0)).normalized()
		#var gravDot = antiGrav.dot(Vector3(0.0, 1.0, 0.0))
		var gravDiffCross = Car.global_transform.basis.y.cross(antiGrav).normalized()
		var gravDiffDot = Car.global_transform.basis.y.dot(antiGrav)
		if acos(gravDiffDot) != 0.0:
			var rotatedBasis = carBasis.rotated(gravDiffCross, acos(gravDiffDot))
			Car.global_transform.basis = lerp(Car.global_transform.basis, rotatedBasis, angular_smooth * delta)
	else:
		var gravDiffCross = Car.global_transform.basis.y.cross(Vector3(0.0, 1.0, 0.0)).normalized()
		var gravDiffDot = Car.global_transform.basis.y.dot(Vector3(0.0, 1.0, 0.0))
		if acos(gravDiffDot) != 0.0:
			var rotatedBasis = carBasis.rotated(gravDiffCross, acos(gravDiffDot))
			Car.global_transform.basis = Car.global_transform.basis.slerp(rotatedBasis, angular_smooth * delta)
	
	var t = -rotari * (Ball.linear_velocity.length()/maxSpeed) * bodytilt
	CarBody.rotation.z = lerp(CarBody.rotation.z, t, 10 * delta)
	if startedDrifting:
		CarModel.rotation.y = lerp(CarModel.rotation.y, carTwist, carTwistRate * delta)
	else :
		CarModel.rotation.y = lerp(CarModel.rotation.y, 0.0, carTwistRate * delta)

func StartDrift():
	drifting = true
	if rotateInput > 0:
		Anim.play("Hop")
	else: if rotateInput < 0:
		Anim.play("HopRight")
	else:
		Anim.play("HopCenter")
	minimumDrift = false
	CarModel.rotation.y = lerp(CarModel.rotation.y, carTwist, 0.2)
	driftDirection = rotateInput
	driftTimer.start()

func StopDrift():
	if minimumDrift:
		boost = 1 + (driftBoost * boostTiering)
		boostTimer.start()
		camAnim.play("ZoomOut")
	drifting = false
	minimumDrift = false

func GetHit(strength : float):
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		Anim.play("Hop")
		pass
	else:
		Anim.play("Hop")
		Ball.angular_velocity = Vector3(0.0, 0.0, 0.0)
		$CarParent_Logic/hurtTimer.start(strength)
		acceleration = hurtSpeed
		pass
	pass

func PickupItem(item : PackedScene):
	itemHeld = item
	hasItem = true

func ThrowItem():
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		pass
	pass

func TriggerRacerAbility():
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		pass
	pass

func SpawnRacer(racer : PackedScene):
	var race: Node = racer.instantiate()
	race.name = str(name)
	
	RacerSpawnLoc.call_deferred("add_child", race)
	
	altItem = race.RacerItem

func _on_drift_timer_timeout() -> void:
	if drifting:
		boostTiering += 1
		boostTiering = clamp(boostTiering, 0, maxBoostTier)
		minimumDrift = true
		driftTimer.start()

func _on_boost_timer_timeout() -> void:
	boost = 1.0
	boostTiering = 0
	camAnim.play("ZoomIn")

func _on_hurt_timer_timeout() -> void:
	acceleration = hurtAccel

func despawn_player(id : int):
	if name.to_int() == id:
		queue_free()
	pass
