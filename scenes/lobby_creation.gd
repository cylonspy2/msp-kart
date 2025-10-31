extends Control

@onready var lobby_name = $"ColorRect/VBoxContainer/LobbyName&Exit/HBoxContainer/TextEdit"
@onready var playCap = $ColorRect/VBoxContainer/PlayerCap/HSlider
@onready var usingSteamToggle = $"ColorRect/VBoxContainer/ServerType&FriendsOnly/CheckButton"
@onready var friendsOnly = $"ColorRect/VBoxContainer/ServerType&FriendsOnly/OptionButton"
@onready var usePwrd = $"ColorRect/VBoxContainer/Server Password/HBoxContainer/CheckButton"
@onready var pwrd = $"ColorRect/VBoxContainer/Server Password/HBoxContainer/TextEdit"
@onready var playCapVal = $ColorRect/VBoxContainer/PlayerCap/Label2
@onready var parent = $".."

func _process(_delta: float) -> void:
	if not visible:
		return
	if lobby_name.text != "":
		HighLevelNetwork.lobbyName = lobby_name.text
	else:
		HighLevelNetwork.lobbyName = "BADDIE343"
	HighLevelNetwork.MAX_PLAYERS = playCap.value
	HighLevelNetwork.STEAM_LOBBY_TYPE = friendsOnly.selected
	playCapVal.text = str(playCap.value)
	if usingSteamToggle.button_pressed:
		parent.useSteam = true
		friendsOnly.visible = true
		HighLevelNetwork.STEAM_LOBBY_TYPE = friendsOnly.selected
		usePwrd.visible = true
		if usePwrd.button_pressed:
			pwrd.visible = true
			HighLevelNetwork.passwordReq = true
			HighLevelNetwork.pwrd = pwrd.text
		else:
			pwrd.visible = false
			HighLevelNetwork.passwordReq = false
	else:
		parent.useSteam = true
		friendsOnly.visible = false
		usePwrd.visible = false
		pwrd.visible = false
