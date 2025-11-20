extends Area3D

@onready var parr = $".."

@rpc("call_local")
func missed_lap(kart : Node3D):
	if kart.haveAuthority:
		pass

@rpc("call_local")
func finished_race(kart : Node3D):
	parr._on_all_done(kart.player_id,  10000 / kart.leaderboard_placement)
