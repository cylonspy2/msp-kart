extends Node

var MAX_PLAYERS : int = 16
var STEAM_LOBBY_TYPE : int = 2
var passwordReq = false
var pwrd = "shadow money wizard gang"
var lobbyName = "BADDIE343"

var lobby_search = ""

signal enter_lobby(id : int)
signal enter_race
signal end_race (id : int, score : int)
signal spawn_racers (spawn_path : NodePath)
signal despawn_player(id : int)

var host_mode_enabled = false
var multiplayer_enabled = false

var PLAYERS : Array = ["localhost"]
var gameStarted = false
var userName : String = "juneEgbert"
var userName_not_steam : String = "ectoBiologist"

var available_items : Array[PackedScene]
var available_ranges : Array[Vector3]

func _set_username(namey : String):
	userName = namey

func _reset_username():
	userName = userName_not_steam

func _set_available_items(items : Array[PackedScene]):
	available_items.clear()
	available_ranges.clear()
	var count : int = 0
	for item : PackedScene in items:
		available_items.append(item)
		var itemn = item.instantiate()
		var ranger = Vector3(itemn.leaderboard_max, itemn.leaderboard_min, count)
		available_ranges.append(ranger)
		count += 1
		itemn.queue_free()
	pass

func _grab_item(placementy : float) -> PackedScene:
	var possible_picks : Array[PackedScene]
	for itemm : Vector3 in available_ranges:
		if itemm.x > placementy and itemm.y < placementy:
			possible_picks.append(available_items[itemm.z])
	if possible_picks.size() > 0:
		var picked = possible_picks.pick_random()
		return picked
	else:
		return possible_picks[0]

#
#func retarget_server(IPA : String, PRT : int) -> void:
	#PORT = PRT
	#IP_ADDRESS = IPA
#
#func start_dedicated_server() -> void :
	#peer = ENetMultiplayerPeer.new()
	#peer.create_server(PORT, MAX_PLAYERS)
	#host_mode_enabled = false
#
#func start_server() -> void :
	#peer = ENetMultiplayerPeer.new()
	#peer.create_server(PORT, MAX_PLAYERS)
	#multiplayer.multiplayer_peer = peer
	#host_mode_enabled = true
#
#func start_client() -> void :
	#peer = ENetMultiplayerPeer.new()
	#peer.create_client(IP_ADDRESS, PORT)
	#multiplayer.multiplayer_peer = peer
