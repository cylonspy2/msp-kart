extends Node3D

@onready var spawner = $MultiplayerSpawner
@onready var UI = $Spectator_ui
@export var camera : Camera3D
@export var requestedTrack : PackedScene
@export var requestedRacer : PackedScene
@export var requestedKart : PackedScene
@export var score : int = 0
var haveAuthority = false
var is_controlled = true

func _enter_tree() -> void:
	is_controlled = true
	set_multiplayer_authority(name.to_int())
	if not is_multiplayer_authority() or OS.has_feature("dedicated_server"): haveAuthority = false
	else : 
		haveAuthority = true
		UI.visible = true
		UI.mouse_filter = UI.MOUSE_FILTER_PASS
	HighLevelNetwork.enter_race.connect(_on_toggle_control)
	multiplayer.peer_disconnected.connect(func(id): despawn_player(id))
	HighLevelNetwork.end_race.connect(func(id, score): finish_race(id, score))
	HighLevelNetwork.enter_race.connect(enter_race)

func _ready() -> void:
	if haveAuthority:
		camera.make_current()

func _process(delta):
	if not haveAuthority or not is_controlled: return
	#print(delta)
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
		spawner.spawn_player(name.to_int())

func finish_race(id : int, score : int):
	if name.to_int() == id:
		camera.make_current()
	$MultiplayerSpawner.despawn_kart(id)
