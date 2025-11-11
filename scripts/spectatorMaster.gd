extends Node3D

@onready var masterCam = $/root/MainScene/MainMenuCam
@onready var spawner = $MultiplayerSpawner
@onready var UI = $Spectator_ui
@export var camera : Camera3D
@export var requestedTrack : PackedScene
@export var requestedRacer : PackedScene
@export var requestedKart : PackedScene
@export var score : int = 0
var haveAuthority = false
var is_controlled = false
var has_spawned = false

var viewing_kart : Node3D

func _enter_tree() -> void:
	is_controlled = true
	set_multiplayer_authority(name.to_int())
	if not is_multiplayer_authority() or OS.has_feature("dedicated_server"): haveAuthority = false
	else : 
		haveAuthority = true
		UI.visible = true
		UI.mouse_filter = UI.MOUSE_FILTER_PASS
	HighLevelNetwork.spawn_racers.connect(func(id, kart) : _on_toggle_control())
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))
	HighLevelNetwork.end_race.connect(func(id, scoree): finish_race(id, scoree))
	HighLevelNetwork.exit_race.connect(reset_lobby)
	HighLevelNetwork.enter_race.connect(enter_race)
	HighLevelNetwork.select_kart.connect(func(id): set_kart(id))
	#HighLevelNetwork.select_kart.connect(func(id): set_kart(id))
	HighLevelNetwork.select_racer.connect(func(id): set_racer(id))
	HighLevelNetwork.select_track.connect(func(id): set_track(id))

func _ready() -> void:
	print("%s entered lobby" % name)
	if haveAuthority:
		camera.make_current()

func _process(_delta : float):
	if not haveAuthority or not is_controlled: 
		UI.visible = false
		return
	
	UI.visible = true
	
	if viewing_kart != null:
		var inputRot = Input.get_action_strength("SteerLeft") - Input.get_action_strength("SteerRight")
		var inputLift = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
		global_position = viewing_kart.global_position
		global_basis.y = viewing_kart.global_basis.y
		global_basis = global_basis.rotated(global_basis.y, inputRot)
		basis = basis.rotated(basis.x, inputLift)
		
		if Input.is_action_just_pressed("Fire"):
			var truInd = wrapi(spawner.kartpath.get_parent().Cars.find(viewing_kart) + 1, 0, spawner.kartpath.get_parent().Cars.length())
			viewing_kart = spawner.kartpath.get_parent().Cars[truInd]
		
		if Input.is_action_just_pressed("Altfire"):
			var truInd = wrapi(spawner.kartpath.get_parent().Cars.find(viewing_kart) - 1, 0, spawner.kartpath.get_parent().Cars.length())
			viewing_kart = spawner.kartpath.get_parent().Cars[truInd]
	else:
		if not spawner.kartpath.get_parent().Cars.is_empty():
			viewing_kart = spawner.kartpath.get_parent().Cars.pick_random()
	
	pass

func reset_lobby():
	is_controlled = false
	masterCam.make_current()
	pass

func _on_toggle_control():
	is_controlled = not is_controlled

func despawn_player(id :int) -> void:
	if name.to_int() == id:
		HighLevelNetwork.despawn_player.emit(id)
		queue_free()
	pass

func enter_race():
	if requestedKart != null and requestedRacer != null:
		UI.visible = false
		UI.mouse_filter = UI.MOUSE_FILTER_IGNORE
		is_controlled = false
		spawner._spawn_Car = requestedKart
		spawner._spawn_Racer = requestedRacer
		#spawner.spawn_kart(name.to_int(), enterP)
		#HighLevelNetwork.spawn_racers.emit(name.to_int(), enterP)
		has_spawned = true

func finish_race(id : int, scoree : int):
	if name.to_int() == id:
		camera.make_current()
	$MultiplayerSpawner.despawn_kart(id)
	has_spawned = false
	is_controlled = true
	score += scoree

func set_kart(id : PackedScene):
	requestedKart = id

func set_racer(id : PackedScene):
	requestedRacer = id

func set_track(id : PackedScene):
	requestedTrack = id
