extends Area3D

@onready var parr = $".."

func missed_lap(kart : Node3D):
	if kart.haveAuthority:
		pass

func finished_race(kart : Node3D):
	parr._on_all_done(kart.player_id,  10000 / kart.leaderboard_placement)
