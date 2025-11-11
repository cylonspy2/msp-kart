extends Control

@export var player_placement_labels : Array[Label]

var finished_racers : Array[int]
var finished_scores : Array[int]

func _ready() -> void:
	HighLevelNetwork.end_race.connect(func(id, scoree): update_leaderboard(id, scoree))
	finished_racers.clear()
	finished_scores.clear()

func update_leaderboard(id: int, scoree: int):
	if not finished_racers.has(id):
		finished_racers.append(id)
		finished_scores.append(scoree)
	else:
		return
	
	if finished_racers.size() > 1:
		finished_racers.sort_custom(func(a,b): return finished_scores[finished_racers.find(a)] > finished_scores[finished_racers.find(b)])
		finished_scores.sort_custom(func(a,b): return a > b)
	
	var count = 0
	for labl in player_placement_labels:
		if count < finished_racers.size():
			labl.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if finished_racers[count] == id:
				add_to_leaderboard(finished_racers[count], finished_scores[count])
			add_to_leaderboard(finished_racers[count], scoree)
		else:
			labl.modulate = Color(1.0, 1.0, 1.0, 0.0)
		count += 1
	pass

func add_to_leaderboard(id : int, scoree : int):
	var usernamee = HighLevelNetwork.userName
	if HighLevelNetwork.multiplayer_enabled and HighLevelNetwork.steam_active == true:
		usernamee = Steam.getFriendPersonaName(id)
	#var usernamee = Steam.getFriendPersonaName(id)
	player_placement_labels[finished_racers.size() - 1].text = String(usernamee + " - " + str(scoree))
	pass
