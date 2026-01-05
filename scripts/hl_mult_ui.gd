extends Control

@export var select_menu_width_count : int = 8
@export var trackListPos = -1
@export var serverBrowserBoxContainer : NodePath
@onready var ServerBroswer = $ServerBrowser
@onready var ServerLobby = $ServerLobby
@onready var LobbyCreate = $LobbyCreation
@onready var MainMenu = $MainMenu
@onready var ServerBrowserScrollbar = $ServerBrowser/Container/ServBrow_Color/ScrollContainer
@onready var lobby_search_bar = $ServerBrowser/Container/SearchHeader/TextEdit
@onready var startGameButton = $ServerLobby/ColorRect/VBoxContainer/HBoxContainer/VBoxContainer/StartGameControl
@onready var lobbyName = $ServerLobby/ColorRect/VBoxContainer/lobby_name
@onready var selectMenu = $SelectionMenu
@onready var selectMenuName = $SelectionMenu/ServBrow_Color/VBoxContainer/Label
@onready var selectMenuHolder = $SelectionMenu/ServBrow_Color/VBoxContainer/ScrollContainer/ServerBrowser
@export var server_button : PackedScene
@export var select_button : PackedScene
@export var select_row : PackedScene
@export var useSteam = true
var haveAuthority = false
var buttonArray : Array
@export var default_racer : PackedScene
@export var default_kart : PackedScene
var chosen_items : Array[PackedScene]
var lobby_idd : int

func _ready() -> void:
	HighLevelNetwork.enter_lobby.connect(_lobby_joined)
	HighLevelNetwork.enter_race.connect(_starting_game)
	HighLevelNetwork.select_track.connect(_back_to_lobby)
	HighLevelNetwork.select_kart.connect(_kart_chosen)
	HighLevelNetwork.select_racer.connect(_racer_chosen)
	HighLevelNetwork.exit_race.connect(func(): _back_to_lobby(null))
	HighLevelNetwork.hosted_lobby.connect(func(_id): host_lobby())
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	if not is_multiplayer_authority() or OS.has_feature("dedicated_server"): haveAuthority = false
	else:
		haveAuthority = true
	
	if OS.has_feature("dedicated_server"):
		#HighLevelNetwork.start_dedicated_server()
		%NetworkManager.start_dedicated_server()

func _process(_delta: float) -> void:
	lobbyName.text = HighLevelNetwork.lobbyName
	if lobby_search_bar.visible:
		HighLevelNetwork.lobby_search = lobby_search_bar.text
	if ServerLobby.visible:
		###alternate inverse formula for this: (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled
		if HighLevelNetwork.get_hosting():
			startGameButton.visible = true
		else:
			startGameButton.visible = false

func host_lobby():
	ServerLobby.visible = true
	ServerLobby.mouse_filter = MOUSE_FILTER_PASS
	HighLevelNetwork.select_kart.emit(default_kart)
	HighLevelNetwork.select_racer.emit(default_racer)

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
		if lobby_name != "":
			var servButton : Control = server_button.instantiate()
			var lobby_mode = Steam.getLobbyData(lobby, "mode")
			var lobby_player_cap = Steam.getLobbyData(lobby, "player cap")
			#var scrip = servButton.get_script()
			
			servButton._setupInfo(lobby_name, lobby_mode, lobby, lobby_player_cap.to_int(), %NetworkManager)
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
	#lobby_idd = targ_lobby_id
	
	buttonArray.clear()
	var sBBC = get_node(serverBrowserBoxContainer)
	if sBBC.get_child_count() > 0:
		for n in sBBC.get_children():
			n.queue_free()
	
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	
	if HighLevelNetwork.trackPosChosen != -1:
		pass
	
	
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
	if useSteam:
		SteamManager._initialize_steam()
		%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM
	else:
		%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.ENET
	%NetworkManager.become_host()

func become_client():
	print("Joining Lobby")
	%NetworkManager.become_client()


func _on_make_server_pressed() -> void:
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = false
	MainMenu.mouse_filter = MOUSE_FILTER_IGNORE
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	LobbyCreate.visible = true
	LobbyCreate.mouse_filter = MOUSE_FILTER_PASS
	
	#become_host()

func _on_exit_pressed() -> void:
	LobbyCreate.visible = false
	LobbyCreate.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = true
	MainMenu.mouse_filter = MOUSE_FILTER_PASS

func _on_make_lobby_pressed() -> void:
	ServerBroswer.visible = false
	ServerBroswer.mouse_filter = MOUSE_FILTER_IGNORE
	MainMenu.visible = false
	MainMenu.mouse_filter = MOUSE_FILTER_IGNORE
	LobbyCreate.visible = false
	LobbyCreate.mouse_filter = MOUSE_FILTER_IGNORE
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
	
	chosen_items.clear()
	
	if %NetworkManager.is_host:
		var userInd = multiplayer.get_peers()
		Steam.getNumLobbyMembers(SteamManager.lobby_id)
		var userID = 0
		if userInd.size() > 1:
			userID = Steam.getLobbyMemberByIndex(SteamManager.lobby_id, userInd.get(randi() % userInd.size()))
			Steam.setLobbyOwner(%NetworkManager.targ_id, userID)
			print(userID)
		else:
			#Steam.deleteLobbyData(%NetworkManager.targ_id)
			#multiplayer.set_multiplayer_peer(SteamMultiplayerPeer.new())
			pass
		Steam.leaveLobby(%NetworkManager.targ_id)
	else:
		Steam.leaveLobby(%NetworkManager.targ_id)
	
	HighLevelNetwork.leave_lobby.emit()


func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_exit_game_pressed() -> void:
	get_tree().quit()


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


func _on_button_2_pressed() -> void:
	list_lobbies()


func _on_exit_lobby_pressed() -> void:
	leave_lobby()


func _on_start_game_pressed() -> void:
	if HighLevelNetwork.get_hosting():
		enter_race.rpc()

@rpc("call_local")
func enter_race():
	
	HighLevelNetwork.enter_race.emit()
	if not chosen_items.is_empty():
		HighLevelNetwork._set_available_items(chosen_items)
	else:
		var path : PackedStringArray = ResourceLoader.list_directory(HighLevelNetwork.ItemPath)
		var hostDir = HighLevelNetwork.ItemPath
		
		for element in path:
			var count = path.find(element)
			var mucho : PackedScene = ResourceLoader.load(hostDir + "/" + path[count])
			chosen_items.append(mucho)
		
		HighLevelNetwork._set_available_items(chosen_items)




func _on_choose_course_pressed() -> void:
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	selectMenu.visible = true
	selectMenu.mouse_filter = MOUSE_FILTER_PASS
	selectMenuName.text = "CHOOSE TRACK"
	populate_choose_menu(0)


func _on_choose_kart_pressed() -> void:
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	selectMenu.visible = true
	selectMenu.mouse_filter = MOUSE_FILTER_PASS
	selectMenuName.text = "CHOOSE KART"
	populate_choose_menu(1)


func _on_choose_racer_pressed() -> void:
	ServerLobby.visible = false
	ServerLobby.mouse_filter = MOUSE_FILTER_IGNORE
	selectMenu.visible = true
	selectMenu.mouse_filter = MOUSE_FILTER_PASS
	selectMenuName.text = "CHOOSE RACER"
	populate_choose_menu(2)


func _racer_chosen(scee : PackedScene):
	default_racer = scee
	_back_to_lobby(PackedScene.new())

func _kart_chosen(scee : PackedScene):
	default_kart = scee
	_back_to_lobby(PackedScene.new())

func _back_to_lobby(_selectedElement : PackedScene):
	ServerLobby.visible = true
	ServerLobby.mouse_filter = MOUSE_FILTER_PASS
	selectMenu.visible = false
	selectMenu.mouse_filter = MOUSE_FILTER_IGNORE


func populate_choose_menu(type : int):
	for thingy in selectMenuHolder.get_children():
		thingy.queue_free()
	
	var path : PackedStringArray
	var hostDir : String
	match(type):
		0:
			path = ResourceLoader.list_directory(HighLevelNetwork.TrackPath)
			hostDir = HighLevelNetwork.TrackPath
		1:
			path = ResourceLoader.list_directory(HighLevelNetwork.KartPath)
			hostDir = HighLevelNetwork.KartPath
		2:
			path = ResourceLoader.list_directory(HighLevelNetwork.RacerPath)
			hostDir = HighLevelNetwork.RacerPath
	#var length = path.size()
	
	var holdz : HBoxContainer
	for element in path:
		var count = path.find(element)
		if count % select_menu_width_count == 0:
			holdz = HBoxContainer.new()
			selectMenuHolder.add_child(holdz)
		var mucho = ResourceLoader.load(hostDir + "/" + path[count])
		var ele = select_button.instantiate()
		var much = mucho.instantiate()
		ele.get_child(0).get_child(0).get_child(1).text = much.name
		match(type):
			0:
				ele.get_child(0).get_child(0).get_child(0).texture = much.map_icon
			1:
				ele.get_child(0).get_child(0).get_child(0).texture = much.kart_icon
			2:
				ele.get_child(0).get_child(0).get_child(0).texture = much.RacerIcon
		much.queue_free()
		ele.type = type
		ele.object = mucho
		holdz.call_deferred("add_child", ele)
