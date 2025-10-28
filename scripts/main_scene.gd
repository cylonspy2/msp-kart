extends Node3D

var chosenTrack : PackedScene
var TrackPath = "res://Racetracks/RacetrackPackedScenes"
var RacerPath = "res://Racers/RacerPackedScenes"
var KartPath = "res://Karts/KartPackedScenes"
var ItemPath = "res://Items/ItemPackedScenes"
@onready var spectatorLobby = $SpectatorLobby

func _enter_tree() -> void:
	HighLevelNetwork.enter_race.connect(start_level)

func _build_available_items_list():
	pass

func _choose_level() -> void :
	var trackArray : Array
	for playeh : Node3D in spectatorLobby.get_children(false):
		var playScrip = playeh.get_script()
		trackArray.append(playScrip.requestedTrack)
		pass
	var trackChoice = trackArray.pick_random()
	if not trackChoice == null :
		chosenTrack = trackChoice
	else :
		var dir = ResourceLoader.list_directory(TrackPath)
		var randInt = randi_range(0, dir.size())
		chosenTrack = ResourceLoader.load(TrackPath + dir[randInt])
	#TODO load in the given track scene here

func start_level() -> void:
	#TODO spawn in the chosen track using _choose_level, and then use the HighLevelNetwork's spawn_racers signal to tell the spectators to spawn their racers in
	pass
