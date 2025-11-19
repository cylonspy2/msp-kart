extends Node3D

@export var username : String = "EctoBiologist"

@export var Racer : PackedScene
@export var RacerSpawnLoc : Node3D

@export var hasItem = false
@export var itemHeld : PackedScene = null
@export var altItem : PackedScene = null

@export_group("Leaderboard Data")
@export var leaderboard_placement : int = 0
@export var laps_made : int = 0
@export var track_pos : float = 0.0
@export var crossed_checkpoints : Array[Area3D]

@onready var MS = $CarParent_Logic/ControlSynchronizer
@onready var UI = $Car/CarLogic/Camera/Car_UI
@onready var Cam = $Car/CarLogic/Camera
@onready var ItemSpawner = $Items/ItemSpawner
@onready var Ball = $Ball
@onready var BallCollisionShape = $Ball/CollisionShape3D
@onready var driftTimer = $CarParent_Logic/driftTimer
@onready var boostTimer = $CarParent_Logic/boostTimer
@onready var hurtTimer = $CarParent_Logic/hurtTimer
@onready var Anim = $CarParent_Logic/AnimationPlayer
@onready var camAnim = $CarParent_Logic/CamAnimationPlayer
@onready var groundRay1 = $Car/CarLogic/RayCast3D1
@onready var groundRay2 = $Car/CarLogic/RayCast3D2
@onready var groundRay3 = $Car/CarLogic/RayCast3D3
@onready var groundRay4 = $Car/CarLogic/RayCast3D4
@onready var CarHitBox = $Car/CarLogic/CarHitbox
@onready var usernameBox = $Car/CarLogic/UsernameHolder/Username
@export_group("Car Model Data")
@export var Car = Node3D
@export var Wheelie : Array[Node3D]
@export var CarBody = MeshInstance3D
@export var CarModel = MeshInstance3D
@export var drift_particles_right : Array[GPUParticles3D]
@export var drift_particles_left : Array[GPUParticles3D]
@export var boost_particles : Array[GPUParticles3D]
@export var hurt_particles : GPUParticles3D

@export_group("Car Stats")
@export var maxSpeed = 15000.0
@export var hurtSpeed = 100.0
@export var acceleration = 900.0
@export var steering = 50.0
@export var steeringDrift = 0.5
@export var steeringAccelMod = 0.4
@export var turnspeed = 0.01
@export var weight = 15.0
@export var driftBoost = 1.75
@export var airControl = 0.1
@export var wallBounce = 0.8

var speedInput = 0.0
var rotateInput = 0.0
var minimumDriftRotation = 2.0
var correctivey = 0.0
@export_group("Car Visual Tweaks")
@export var kart_icon : Texture2D
@export var bodytilt = 30.0
@export var wheelTwist = 0.5
@export var maxCarTwist = 30.0
@export var carTwistRate = 5.0
var carTwist = 0.0
var faceForce = Vector3(0.0, 0.0, 1.0)
@export_group("Car Drift Particle coloring")
@export var sparkMat : BaseMaterial3D
@export var base_color : Color
@export var tier_1_color : Color
@export var tier_2_color : Color
@export var tier_3_color : Color
@export var tier_4_color : Color
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
@export var velocity_smooth = 1.0
@export var angular_smooth = 3.64
@export var start_drift = false
@export var end_drift = false
@export var firedItem = false
@export var altFiredItem = false
@export var cam_looking_back = false
@export var cam_looking_front = false
@export var server_Pos : Vector3
@export var server_Rot : Basis
@export var server_Pos_Offset : Vector3
@export var time_since_last_update : float
@export var fireDisabled = false
@export var hasControl = true
@export var gravForce = Vector3(0.0, -1.0, 0.0)
@export var floorDir = Vector3(0.0, -1.0, 0.0)
@export var antigrav_allowed = true

var lockedCamPos = Vector3(0.0, 0.0, 0.0)
var lockedCamRot : Basis

var gravDir : Vector3
var hurtAccel : float
var camStartPos : Vector3
var camStartRot : Basis
var camLocked = false
var is_touching_ground = true
var can_look_back = true

@export var player_id := 1:
	set(id):
		player_id = id
		%ControlSynchronizer.set_multiplayer_authority(id)

func _enter_tree():
	fireItem.connect(ThrowItem)
	altFireItem.connect(ThrowItem)
	gainItem.connect(func(id) : PickupItem(id))
	HighLevelNetwork.leave_lobby.connect(func(): queue_free())

func _ready():
	print("%s ready, with controller %s" % [name, player_id])
	
	$Car/CarLogic/CarHitbox.name = str(player_id)
	#weight = Ball.mass
	hurt_particles.emitting = false
	
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
	camStartPos = Cam.position
	camStartRot = Cam.basis
	
	for part in drift_particles_right:
		part.emitting = false
	for part in drift_particles_left:
		part.emitting = false

func _physics_process(_delta):
	if is_queued_for_deletion():
		return
	
	if not HighLevelNetwork.get_hosting(): 
		time_since_last_update += _delta
	else:
		server_Pos_Offset = Vector3()
		time_since_last_update = 0.0
	
	if Ball.linear_velocity.length() > maxSpeed and boost <= 1:
		var cappa = (Ball.linear_velocity / maxSpeed).normalized()
		Ball.linear_velocity = cappa * maxSpeed
	
	var bla = (Car.transform.origin - Ball.transform.origin).length()
	if bla > velocity_smooth:
		Car.transform.origin = Car.transform.origin.move_toward(Ball.transform.origin, bla - (velocity_smooth * 0.5))
	else:
		Car.transform.origin = Car.transform.origin.move_toward(Ball.transform.origin, (velocity_smooth * 0.5))
	
	var forceForce = (Car.global_transform.basis.z * speedInput)
	gravDir = gravForce * 9.810 * weight
	var hitr = Ball.move_and_collide(gravDir * _delta, true)
	if not hitr:
		forceForce *= airControl
		is_touching_ground = false
	else:
		is_touching_ground = true
	
	var lerpForce = lerp(((forceForce * boost)), prevForce, clamp(prevForce.length(), 0.0, 1.0) * _delta)
	var true_vel = ((lerpForce * _delta) + (_delta * Ball.linear_velocity))
	if drifting :
		lerpForce = lerp(lerpForce, prevForce, steeringAccelMod)
		true_vel = lerp(true_vel, (_delta * Ball.linear_velocity) * 2, steeringAccelMod)
	
	##code for when the kart's own hitbox detects collisions
	var hitS : KinematicCollision3D = CarHitBox.move_and_collide(true_vel * _delta, true, 0.01, true)
	if hitS != null:
		Ball.transform.origin = Car.transform.origin#.move_toward(Car.transform.origin - ModelOffset, 100)
		var hitted = hitS.get_collider(0)
		if hitted.name != "Rim":
			if hitted.name != "CarHitBox":
				#print("%s Hit a Gadget or Item, which should have its own things to say about this" % username)
				pass
			else:
				#print("%s Hit another car" % username)
				_process_kart_collision(hitS, wallBounce / weight)
				pass
			pass
		else:
			#print("%s Hit track guardrail" % username)
			_process_kart_collision(hitS, wallBounce)
			pass
		pass
	else:
		#Ball.transform.origin = Ball.transform.origin.move_toward(Car.transform.origin - ModelOffset, _delta)
		Ball.apply_central_force(lerpForce)
		prevForce = lerpForce
		pass
	
	if is_touching_ground:
		hitr = Ball.move_and_collide(gravDir * weight * _delta, true, 0.01, true)
	else:
		hitr = Ball.move_and_collide(gravDir * _delta * (boost * driftBoost), true, 0.01, true)
	if hitr:
		Ball.gravity_scale = 0.0
		var avgHitPos = Vector3(0.0, 0.0, 0.0)
		var b = 0
		while b < hitr.get_collision_count():
			avgHitPos += hitr.get_position(b)
			b += 1
		avgHitPos /= b
		var newGrav = (-(Ball.global_position - avgHitPos)).normalized()
		floorDir = lerp(gravForce, newGrav, clamp(_delta * 20 * rad_to_deg(gravForce.dot(newGrav)), 0.0, 1.0))
		if antigrav_allowed:
			gravForce = floorDir
		else:
			gravForce = Vector3(0.0, -1.0, 0.0)
		notify_property_list_changed()
		pass
	else:
		Ball.gravity_scale = 3.0
		#forceForce *= 0
		floorDir = Vector3(0.0, -1.0, 0.0)
		gravForce = floorDir
		notify_property_list_changed()
		Ball.apply_central_force(gravForce * 9.81 * weight)
		pass
	gravDir = gravForce * weight * 3
	Ball.move_and_collide(gravDir * _delta)
	
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		server_Pos_Offset += Ball.global_position - server_Pos
		Ball.global_position.slerp(server_Pos + server_Pos_Offset, clamp(1 - time_since_last_update, 0, 1))
		Car.global_transform.basis.slerp(server_Rot, clamp(1 - (time_since_last_update * 1000), 0, 1))
		pass
	else:
		server_Pos = Ball.global_position
		server_Rot = Car.global_transform.basis
		pass
	
	#print(Ball.angular_velocity.length())

func _process_kart_collision(hitter : KinematicCollision3D, bounce : float) -> Vector3:
	var _avgHitShellPos = Vector3(0.0, 0.0, 0.0)
	var avgHitNorm = Vector3(0.0, 0.0, 0.0)
	var b = 0
	while b < hitter.get_collision_count():
		_avgHitShellPos += hitter.get_position(b)
		avgHitNorm += hitter.get_normal(b)
		b += 1
	_avgHitShellPos /= b
	avgHitNorm /= b
	
	var boo = hitter.get_remainder().normalized() * Ball.linear_velocity.length()
	var boonce = (boo.bounce(avgHitNorm) * bounce)
	var foonce = (Ball.linear_velocity.bounce(avgHitNorm))
	Ball.linear_velocity = foonce
	Ball.apply_central_force(avgHitNorm * Ball.linear_velocity.length())
	Ball.apply_central_force(boonce)
	prevForce = boonce
	return boonce

func _process(delta):
	
	if hasControl:
		if Cam == null:
			return
		else:
			speedInput = (MS.inputDir) * acceleration
			rotateInput = deg_to_rad(steering) * (MS.inputRot) ## * (Ball.linear_velocity.length() / maxSpeed)
			if speedInput < 0.0:
				rotateInput *= -1
			lockedCamPos = null
			Cam.position = camStartPos
			Cam.basis = camStartRot
			camLocked = true
	else:
		speedInput = 0.0
		rotateInput = 0.0
		if camLocked == true:
			if lockedCamPos == null:
				lockedCamPos = Cam.global_position
				lockedCamRot = Cam.global_basis
			else:
				Cam.global_position = lockedCamPos
				Cam.global_basis = lockedCamRot
		else:
			if lockedCamPos != null:
				Cam.global_position = lockedCamPos
				Cam.global_basis = lockedCamRot
				lockedCamPos = null
			else:
				Cam.position = lerp(Cam.position, camStartPos, 0.1)
				Cam.basis = lerp(Cam.basis.orthonormalized(), camStartRot, 0.1).orthonormalized()
	
	
	var hiter = Ball.move_and_collide(gravDir * delta, true)
	if not hiter:
		rotateInput *= airControl
	
	for wheel : Node3D in Wheelie:
		wheel.rotation.y = lerp(wheel.rotation.y, rotateInput * wheelTwist, 5 * delta)
	
	if multiplayer.is_server() or not HighLevelNetwork.multiplayer_enabled: 
		## serverwork + singleplayer work
		pass
	
	if haveAuthority && usernameBox != null:
		usernameBox.text = username
	
	if firedItem:
		if (itemHeld != null) && not fireDisabled:
			fireItem.emit(itemHeld)
			itemHeld = null
			hasItem = false
		firedItem = false
	if altFiredItem:
		if (altItem != null && itemHeld != null) && not fireDisabled:
			altFireItem.emit(altItem)
			itemHeld = null
			hasItem = false
		altFiredItem = false
	
	if start_drift:
		start_drift = false
		if not drifting and rotateInput != 0 and (speedInput > 0.0 and Ball.linear_velocity.length() > 1):
			boostTiering = 0
			startDriftDirection = MS.inputRot
			carTwist = deg_to_rad(maxCarTwist * startDriftDirection)
			startedDrifting = true
			StartDrift()
	
	if drifting:
		#var driftAmount = lerp(rotateInput,(deg_to_rad(steering * (1 + steeringDrift)) * startDriftDirection), steeringDrift)
		var driftAmount = rotateInput + ((deg_to_rad(steering) * (startDriftDirection)) * steeringDrift)
		rotateInput = lerp(rotateInput, driftAmount, turnspeed)
		#rotateInput += driftDirection + driftAmount
		match boostTiering:
			1:
				sparkMat.albedo_color = tier_1_color
				sparkMat.emission = tier_1_color
			2:
				sparkMat.albedo_color = tier_2_color
				sparkMat.emission = tier_2_color
			3:
				sparkMat.albedo_color = tier_3_color
				sparkMat.emission = tier_3_color
			4:
				sparkMat.albedo_color = tier_4_color
				sparkMat.emission = tier_4_color
			_:
				sparkMat.albedo_color = base_color
				sparkMat.emission = base_color
	
	if end_drift or ((speedInput <= 0.1) or not is_touching_ground or Ball.linear_velocity.length() <= 1):
		end_drift = false
		if drifting:
			start_drift = false
			startedDrifting = false
			driftTimer.stop()
			drifting = false
			StopDrift()
	
	if Ball.linear_velocity.length() > 0.1 :
		turnable = true
	else:
		turnable = false
	RotateCar(delta)
	
	if camLocked and hasControl:
		#print(str(can_look_back) + " " + str(cam_looking_back) + " " + str(cam_looking_front))
		if cam_looking_back and can_look_back:
			camAnim.play("LookBack")
			cam_looking_back = false
		else:
			cam_looking_back = false
		if cam_looking_front and can_look_back:
			camAnim.play("LookFront")
			cam_looking_front = false
	else:
		cam_looking_back = false
		cam_looking_front = false
	
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		##server producing data for clients
		pass

func RotateCar(delta):
	var antiGrav = -floorDir
	var rotari = rotateInput
	var speedModif = clampf(0.01 * Ball.linear_velocity.length(), 0.0, 1.0) 
	
	var carBasis = Car.global_transform.basis.orthonormalized()
	if not turnable :
		rotari = 0.0
	var newBasis = Car.transform.basis.rotated(Car.transform.basis.y, rotari).get_rotation_quaternion()
	Car.transform.basis = Car.transform.basis.orthonormalized().slerp(newBasis, speedModif * delta)
	Car.transform.basis = Car.transform.basis.orthonormalized()
	carBasis = Car.global_transform.basis.orthonormalized()
	#var veloc_modif = clampf(Ball.linear_velocity.length(), 0.0, 100.0) * 0.01
	
	if Vector3(0.0, 1.0, 0.0) != antiGrav:
		#var gravCross = antiGrav.cross(Vector3(0.0, 1.0, 0.0)).normalized()
		#var gravDot = antiGrav.dot(Vector3(0.0, 1.0, 0.0))
		var gravDiffCross = Car.global_transform.basis.y.cross(antiGrav).normalized()
		var gravDiffDot = Car.global_transform.basis.y.dot(antiGrav)
		if acos(gravDiffDot) != 0.0:
			var rotatedBasis = carBasis.rotated(gravDiffCross, acos(gravDiffDot))
			#var rotat_For = veloc_modif * angular_smooth * delta
			var rotat_For = angular_smooth * delta
			Car.global_transform.basis = lerp(Car.global_transform.basis, rotatedBasis, rotat_For)
	else:
		var gravDiffCross = Car.global_transform.basis.y.cross(Vector3(0.0, 1.0, 0.0)).normalized()
		var gravDiffDot = Car.global_transform.basis.y.dot(Vector3(0.0, 1.0, 0.0))
		if acos(gravDiffDot) != 0.0:
			var rotatedBasis = carBasis.rotated(gravDiffCross, acos(gravDiffDot))
			#var rotat_For = veloc_modif * angular_smooth * delta
			var rotat_For = angular_smooth * delta
			Car.global_transform.basis = Car.global_transform.basis.slerp(rotatedBasis, rotat_For)
	
	var t = clampf(-rotari * (Ball.linear_velocity.length()/maxSpeed) * bodytilt, -maxCarTwist, maxCarTwist)
	CarBody.rotation.z = lerp(CarBody.rotation.z, t, 10 * delta)
	if startedDrifting:
		CarModel.rotation.y = lerp(CarModel.rotation.y, carTwist, carTwistRate * delta)
	else :
		CarModel.rotation.y = lerp(CarModel.rotation.y, 0.0, carTwistRate * delta)

func StartDrift():
	drifting = true
	if rotateInput > 0:
		Anim.play("Hop")
		if haveAuthority:
			for part in drift_particles_left:
				part.emitting = true
	else: if rotateInput < 0:
		Anim.play("HopRight")
		if haveAuthority:
			for part in drift_particles_right:
				part.emitting = true
	else:
		Anim.play("HopCenter")
		if haveAuthority:
			for part in drift_particles_right:
				part.emitting = true
			for part in drift_particles_left:
				part.emitting = true
	minimumDrift = false
	CarModel.rotation.y = lerp(CarModel.rotation.y, carTwist, 0.2)
	driftDirection = rotateInput
	driftTimer.start()

func StopDrift():
	if minimumDrift and is_touching_ground:
		boost = 1 + (driftBoost * boostTiering)
		boostTimer.start()
		can_look_back = false
		camAnim.play("ZoomOut")
		if haveAuthority:
			for part in boost_particles:
				part.restart(false)
				part.emitting = true
	for part in drift_particles_right:
		part.emitting = false
	for part in drift_particles_left:
		part.emitting = false
	drifting = false
	minimumDrift = false

func GetHit(strength : float):
	if not HighLevelNetwork.get_hosting(): 
		Anim.play("Hop")
		hurt_particles.emitting = true
		fireDisabled = true
		pass
	else:
		Anim.play("Hop")
		RacerSpawnLoc.get_child(0).hurt = true
		hurt_particles.emitting = true
		fireDisabled = true
		acceleration = hurtSpeed
		speedInput = (MS.inputDir) * acceleration
		Ball.linear_velocity = Vector3.ZERO
		hurtTimer.start(strength)
		pass
	pass

func GetSlowed(strength : float):
	if not HighLevelNetwork.get_hosting(): 
		pass
	else:
		acceleration = hurtSpeed
		speedInput = (MS.inputDir) * acceleration
		Ball.linear_velocity = Vector3.ZERO
		#Ball.axis_lock_linear_x = true
		#Ball.axis_lock_linear_y = true
		#Ball.axis_lock_linear_z = true
		hurtTimer.start(strength)
		pass
	pass

func PickupItem(item : PackedScene):
	if hasItem:
		return
	if item != null:
		RacerSpawnLoc.get_child(0).hold_item = true
		itemHeld = item
		hasItem = true

func ThrowItem(_item : PackedScene):
	RacerSpawnLoc.get_child(0).hold_item = false
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		fireDisabled = true
		$CarParent_Logic/itemTimer.start()
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
	can_look_back = true

func _on_hurt_timer_timeout() -> void:
	#Ball.axis_lock_linear_x = false
	#Ball.axis_lock_linear_y = false
	#Ball.axis_lock_linear_z = false
	hurt_particles.emitting = false
	acceleration = hurtAccel
	fireDisabled = false
	RacerSpawnLoc.get_child(0).hurt = false

func _on_item_timer_timeout() -> void:
	hasItem = false
	itemHeld = null
	fireDisabled = false

func _recover():
	Ball.axis_lock_linear_x = true
	Ball.axis_lock_linear_y = true
	Ball.axis_lock_linear_z = true
	camLocked = false
	Anim.play("recover")

func _all_done_recovering():
	Ball.axis_lock_linear_x = false
	Ball.axis_lock_linear_y = false
	Ball.axis_lock_linear_z = false
	hasControl = true

func despawn_player(id : int):
	if name.to_int() == id:
		queue_free()
	pass
