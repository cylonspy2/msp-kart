extends Area3D



##COMMENT: This is a default template for your map's objective data,
## set up for a barebones leaderboard style race

##COMMENT:  This script doesn't *have* to be replaced with a fresh one for each track,
## but if you want to make a different kind of objective for it, like a battle map for example, 
## this is where that logic goes

func missed_lap(kart : Node3D):
	if kart.haveAuthority:
		pass

func finished_race(kart : Node3D):
	if kart.haveAuthority:
		HighLevelNetwork.end_race.emit(kart.player_id, kart.leaderboard_placement * 1000)
