extends Node3D

@export var levelChosen = false
@export var trackListPos = -1
@export var chosenTrack : PackedScene
#var TrackPath = "res://Racetracks/RacetrackPackedScenes"
#var RacerPath = "res://Racers/RacerPackedScenes"
#var KartPath = "res://Karts/KartPackedScenes"
#var ItemPath = "res://Items/ItemPackedScenes"
@onready var spectatorLobby = $SpectatorLobby
@onready var MainUI = $MainMenuCam/HLMultUI
@onready var MainSpawner = $MultiplayerSpawner
@onready var levelChooserAnim = $LevelChooser
@onready var Environ = $Environment3D

@export var itemIndexArray : Array[int]

func _enter_tree() -> void:
	HighLevelNetwork.enter_race.connect(_choose_level)
	HighLevelNetwork.end_race.connect(_ending_race)
	HighLevelNetwork.exit_race.connect(end_level)

func _process(_delta: float) -> void:
	if levelChosen:
		levelChooserAnim.play("CHOOSE")
		levelChosen = false
	else:
		#MainUI.trackListPos = -1
		pass
	
	HighLevelNetwork.trackPosChosen = trackListPos

func update_item_array(items : Array[int]):
	if HighLevelNetwork.host_mode_enabled or OS.has_feature("dedicated_server"):
		itemIndexArray = items

func _build_available_items_list():
	var arr : Array[PackedScene]
	var path = ResourceLoader.list_directory(HighLevelNetwork.ItemPath)
	#TODO: modify this iterator to pull from a list prebuilt by Host and synced with a MultiplayerSynch (itemIndexArray)
	for element in path:
		var count = path.find(element)
		arr.append(ResourceLoader.load(HighLevelNetwork.ItemPath + "/" + path[count]))
	HighLevelNetwork._set_available_items(arr)
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
		var dir = ResourceLoader.list_directory(HighLevelNetwork.TrackPath)
		var randInt = randi_range(0, dir.size())
		MainUI.trackListPos = randInt
		trackListPos = randInt


func _on_level_chooser_animation_finished(_anim_name: StringName) -> void:
	var dir = ResourceLoader.list_directory(HighLevelNetwork.TrackPath)
	chosenTrack = ResourceLoader.load(HighLevelNetwork.TrackPath + "/" + dir[trackListPos])
	start_level()

func start_level() -> void:
	Environ.visible = false
	_build_available_items_list()
	MainSpawner.spawn_level(chosenTrack)
	HighLevelNetwork.spawn_racers.emit(MainSpawner.racerSpawnpath)
	if HighLevelNetwork.host_mode_enabled && %NetworkManager.MULTIPLAYER_NETWORK_TYPE == %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM:
		pass
	pass

func _ending_race(id : int, score : int):
	##TODO: make a system to keep track of the cumulative score of lobby members
	pass

func end_level():
	for blabla : Node3D in get_node(MainSpawner.trackSlot).get_children():
		blabla.queue_free()
	Environ.visible = true
	if HighLevelNetwork.host_mode_enabled && %NetworkManager.MULTIPLAYER_NETWORK_TYPE == %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM:
		pass
	pass
