extends Node3D

@export var MAX_LAPS : int

@onready var finish_line = $Finish_Line
@export var Car_Root : Array[NodePath]
@export var TrackPath : Path3D
@export var checkpoints : Array[Node3D]
@export var Cars : Array[Node3D]
@export var RacerIcons : Array[TextureRect]
@onready var Path = $Minimap/Minimap_road/Path2D
@onready var ItemIcon = $Minimap/Item_Visualizer/VBoxContainer/Item/TextureRect/ItemIcon
@onready var AltItemIcon = $Minimap/Item_Visualizer/VBoxContainer/AltItem/TextureRect2/AltItemIcon

var yourAuthority : int

func _ready() -> void:
	$Minimap/Minimap_road/Line2D.clear_points()
	$Minimap/Minimap_road/Line2D2.clear_points()
	RacerIcons.clear()
	
	yourAuthority = get_multiplayer_authority()
	
	for car in Cars:
		var racee = car.Racer.instantiate()
		var carIcon = racee.RacerIcon
		var racer: TextureRect = TextureRect.new()
		racer.name = str(car.player_id)
		racer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		racer.texture = carIcon
		racer.size = Vector2(32, 32)
		racer.position = Path.curve.sample_baked(0.0) + Vector2(-16,-16)
		$Minimap/Minimap_road/Path2D.call_deferred("add_child", racer)
		RacerIcons.append(racer)
		if yourAuthority == car.player_id: 
			var rep = racee.RacerItem.instantiate()
			$Minimap/Item_Visualizer/VBoxContainer/AltItem/TextureRect2/AltItemIcon.texture = rep.inventory_icon
			rep.queue_free()
		racee.queue_free()
	var pointCol = Path.curve.get_baked_points()
	for point in pointCol:
		$Minimap/Minimap_road/Line2D.add_point(point)
		$Minimap/Minimap_road/Line2D2.add_point(point)

func _process(_delta: float) -> void:
	if not (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled:
		return
	
	for car in Cars:
		car.track_pos = get_track_placement(car.Ball.global_position)
		#print(car.track_pos)
		var indec = RacerIcons.find_custom(func(a): return str(car.player_id) == a.name)
		var icon = RacerIcons[indec]
		icon.position = Path.curve.sample_baked(car.track_pos * Path.curve.get_baked_length()) + Vector2(-16,-16)
		#print(indec)
	
	Cars.sort_custom(func(a, b): return a.track_placement + a.laps_made > b.track_placement + b.laps_made)
	
	for car in Cars:
		var placement = Cars.find(car) + 1
		car.leaderboard_placement = placement
		
		#if the current racer isn't yours, don't bother doing the UI work
		if yourAuthority != car.player_id: continue
		
		##TODO: All UI work that is specific to the given racer
		
		if ItemIcon.texture == null:
			if car.hasItem:
				var Itemm = car.itemHeld.instantiate()
				ItemIcon.texture = Itemm.inventory_icon
				Itemm.queue_free()
		else:
			if not car.hasItem:
				ItemIcon.texture = null
		
		if car.fireDisabled:
			$Minimap/Item_Visualizer/VBoxContainer/Item/TextureRect/ColorRect.visible = true
			$Minimap/Item_Visualizer/VBoxContainer/AltItem/TextureRect2/ColorRect.visible = true
		else:
			$Minimap/Item_Visualizer/VBoxContainer/Item/TextureRect/ColorRect.visible = false
			$Minimap/Item_Visualizer/VBoxContainer/AltItem/TextureRect2/ColorRect.visible = false
		
		$Minimap/Placement/Rank.text = str(placement)
		match(placement):
			1:
				$Minimap/Placement/Denotion.text = "st"
			2:
				$Minimap/Placement/Denotion.text = "nd"
			3:
				$Minimap/Placement/Denotion.text = "rd"
			_:
				$Minimap/Placement/Denotion.text = "th"

func update_lapcount(checkpointers : Array[Node3D], lap_count : int) -> int:
	if (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		return -1
	
	if checkpoints.size() == checkpointers.size():
		return lap_count + 1
	return lap_count

func get_track_placement(global_loc : Vector3) -> float:
	var curvy = TrackPath.curve
	var curv_space_pos = global_loc - TrackPath.global_position
	return curvy.get_closest_offset(curv_space_pos) / curvy.get_baked_length()
	#return ((curvy.get_baked_points().find(curvy.get_closest_point(curv_space_pos))) / curvy.get_baked_length()) + curvy.get_closest_offset(curv_space_pos)

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
