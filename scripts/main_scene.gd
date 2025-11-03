extends Node3D

@export var levelChosen = false
@export var trackListPos = -1
@export var chosenTrack : PackedScene
var TrackPath = "res://Racetracks/RacetrackPackedScenes"
var RacerPath = "res://Racers/RacerPackedScenes"
var KartPath = "res://Karts/KartPackedScenes"
var ItemPath = "res://Items/ItemPackedScenes"
@onready var spectatorLobby = $SpectatorLobby
@onready var MainUI = $MainMenuCam/HLMultUI
@onready var MainSpawner = $MultiplayerSpawner
@onready var levelChooserAnim = $LevelChooser

func _enter_tree() -> void:
	HighLevelNetwork.enter_race.connect(_choose_level)
	HighLevelNetwork.exit_race.connect(end_level)

func _process(_delta: float) -> void:
	if levelChosen:
		levelChooserAnim.play("CHOOSE")
		levelChosen = false
	else:
		#MainUI.trackListPos = -1
		pass
	
	HighLevelNetwork.trackPosChosen = trackListPos

func _build_available_items_list():
	pass

func _choose_level() -> void :
	if not (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled:
		return
	var trackArray : Array
	for playeh : Node3D in spectatorLobby.get_children(false):
		var playScrip = playeh.get_script()
		trackArray.append(playScrip.requestedTrack)
		pass
	var trackChoice = trackArray.pick_random()
	if not trackChoice == null :
		trackListPos = trackArray.find(chosenTrack)
	else :
		var dir = ResourceLoader.list_directory(TrackPath)
		var randInt = randi_range(0, dir.size())
		MainUI.trackListPos = randInt
		trackListPos = randInt


func _on_level_chooser_animation_finished(_anim_name: StringName) -> void:
	var dir = ResourceLoader.list_directory(TrackPath)
	chosenTrack = ResourceLoader.load(TrackPath + dir[trackListPos])
	start_level()

func start_level() -> void:
	MainSpawner.spawn_level(chosenTrack)
	HighLevelNetwork.spawn_racers.emit(MainSpawner.racerSpawnpath)
	if HighLevelNetwork.host_mode_enabled && %NetworkManager.MULTIPLAYER_NETWORK_TYPE == %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM:
		pass
	pass

func end_level():
	#TODO despawn racetrack
	if HighLevelNetwork.host_mode_enabled && %NetworkManager.MULTIPLAYER_NETWORK_TYPE == %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM:
		pass
	pass
