extends Node3D

@export var MAX_LAPS : int

@onready var finish_line = $Finish_Line
@export var Car_Root : Array[NodePath]
@export var TrackPath : Path3D
@export var checkpoints : Array[Node3D]
@export var Cars : Array[Node3D]

func _process(delta: float) -> void:
	if (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		return
	
	for car in Cars:
		car.track_pos = get_track_placement(car.global_position)
	Cars.sort_custom(func(a, b): return a.track_placement + a.laps_made > b.track_placement + b.laps_made)
	
	for car in Cars:
		car.leaderboard_placement = Cars.find(car)

func update_lapcount(checkpointers : Array[Node3D], lap_count : int) -> int:
	if (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		return -1
	
	if checkpoints.size() == checkpointers.size():
		return lap_count + 1
	return lap_count

func get_track_placement(global_loc : Vector3) -> float:
	var curvy = TrackPath.curve
	var curv_space_pos = global_loc - TrackPath.global_position
	return ((curvy.get_baked_points().find(curvy.get_closest_point(curv_space_pos))) / curvy.get_baked_length()) + curvy.get_closest_offset(curv_space_pos)

func _on_finish_line_body_entered(body: Node3D) -> void:
	if (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		return
	if body.has_node("CarParent_Logic"):
		var updatd_lap_count = update_lapcount(body.crossed_checkpoints, body.laps_made)
		if updatd_lap_count == -1:
			finish_line.missed_lap(body)
			return
		else:
			body.laps_made = updatd_lap_count
			if updatd_lap_count >= MAX_LAPS:
				finish_line.finished_race(body)
