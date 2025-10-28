extends Control

@export var serverBrowserBoxContainer : NodePath
@onready var ServerBroswer = $ServerBrowser
@onready var ServerLobby = $ServerLobby
@onready var MainMenu = $MainMenu
@onready var ServerBrowserScrollbar = $ServerBrowser/Container/ServBrow_Color/ScrollContainer
@export var server_button : PackedScene
@export var useSteam = true
var buttonArray : Array

func _ready() -> void:
	HighLevelNetwork.enter_lobby.connect(_lobby_joined)
	HighLevelNetwork.enter_race.connect(_starting_game)
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	
	if OS.has_feature("dedicated_server"):
		#HighLevelNetwork.start_dedicated_server()
		%NetworkManager.start_dedicated_server()

func list_lobbies():
	print("finding all the Steam Lobbies")
	if %NetworkManager.network_is_steam == true:
		SteamManager._initialize_steam()
		HighLevelNetwork._set_username(Steam.getPersonaName())
		Steam.lobby_match_list.connect(func(lobbies): _populate_lobbies(lobbies))
	else:
		HighLevelNetwork.reset_username()
		Steam.lobby_match_list.disconnect(func(lobbies): _populate_lobbies(lobbies))
	%NetworkManager.list_lobbies()

func _populate_lobbies(lobbies : Array) -> void:
	#return
	buttonArray.clear()
	var sBBC = get_node(serverBrowserBoxContainer)
	if sBBC.get_child_count() > 0:
		for n in sBBC.get_children():
			n.queue_free()

	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		print("lobby found: " + lobby_name)
		if lobby_name != "" && lobby_name == "BADDIE313":
			var servButton : Control = server_button.instantiate()
			var lobby_mode = Steam.getLobbyData(lobby, "mode")
			var lobby_player_cap = Steam.getLobbyData(lobby, "player cap")
			#var scrip = servButton.get_script()
			
			servButton._setupInfo(lobby_name, lobby_mode, lobby, lobby_player_cap.to_int())
			buttonArray.append(servButton)
			_connect_join_button(servButton)
			get_node(serverBrowserBoxContainer).call_deferred("add_child", servButton)
		
	
	#once done, clean up
	
	pass

func _connect_join_button(servButt) -> void:
	HighLevelNetwork.enter_lobby.connect(func(targ_lobby_id): servButt._trigger_lobby(targ_lobby_id))

func _serverr_joined(targ_lobby_id = 0) -> void:
	print("joined lobby located at %s" % targ_lobby_id)
	#%NetworkManager.become_client()
	
	buttonArray.clear()
	var sBBC = get_node(serverBrowserBoxContainer)
	if sBBC.get_child_count() > 0:
		for n in sBBC.get_children():
			n.queue_free()
	
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = true
	ServerLobby.mouse_filter = MOUSE_FILTER_PASS

func _lobby_joined(targ_lobby_id = 0) -> void:
	print("joined lobby %s" % targ_lobby_id)
	#%NetworkManager.become_client(targ_lobby_id)
	
	buttonArray.clear()
	var sBBC = get_node(serverBrowserBoxContainer)
	if sBBC.get_child_count() > 0:
		for n in sBBC.get_children():
			n.queue_free()
	
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = true
	ServerLobby.mouse_filter = MOUSE_FILTER_PASS

func _starting_game() -> void:
	
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = false
	MainMenu.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	
	pass

#func _on_server_pressed() -> void:
	#HighLevelNetwork.start_server()
	##HighLevelNetwork.start_client()
#
#
#func _on_client_pressed() -> void:
	#HighLevelNetwork.start_client()


func become_host(): #Will need work for dedicated servers
	print("Hosting Lobby")
	%NetworkManager.become_host()

func become_client():
	print("Joining Lobby")
	%NetworkManager.become_client()


func _on_make_server_pressed() -> void:
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = false
	MainMenu.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = true
	ServerLobby.mouse_filter = MOUSE_FILTER_PASS
	
	become_host()


func _on_find_server_pressed() -> void:
	ServerBroswer.visible = true
	ServerBroswer.mouse_filter = MOUSE_FILTER_PASS
	MainMenu.visible = false
	MainMenu.mouse_filter = MOUSE_FILTER_IGNORE
	
	
	
	list_lobbies()


func leave_lobby():
	print("Leaving Lobby")
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = true
	MainMenu.mouse_filter = MOUSE_FILTER_PASS
	
	if %NetworkManager.is_host:
		Steam.leaveLobby(%NetworkManager.targ_id)
	else:
		Steam.leaveLobby(%NetworkManager.targ_id)


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_pressed() -> void:
	pass # Replace with function body.


func _on_close_pressed() -> void:
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = true
	MainMenu.mouse_filter = MOUSE_FILTER_PASS


func _on_server_type_pressed() -> void:
	useSteam = not useSteam
	if useSteam:
		%ServerType.text = "STEAM"
		%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM
	else:
		%ServerType.text = "ENET"
		%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.ENET
	
	list_lobbies()
