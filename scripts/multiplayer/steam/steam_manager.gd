extends Node

var is_owned: bool = false
var steam_app_id: int = 480   # test game app id
var steam_id: int = 0
var steam_username: String = ""

var lobby_id = 0
var lobby_max_members = 4

func _init():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _process(delta: float) -> void:
	Steam.run_callbacks()

func _initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Steam Initialized? %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Steam Initialization failed. Did you make sure to open Steam? Shutting Down. %s " % initialize_response)
		get_tree().quit()
	
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	print("steam id: %s" % steam_id)
	print("steam username: %s" % steam_username)
	
	if is_owned == false:
		print("You didn't download this from Steam, did you.")
	
