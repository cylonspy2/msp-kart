extends Node3D


@export var map_icon : Texture2D

@export var MAX_LAPS : int

@onready var animplayer = $Minimap/NewLap
@onready var finish_line = $Finish_Line
@export var Car_Root : Array[Node3D]
@export var TrackPath : Path3D
@export var checkpoints : Array[Area3D]
@export var Cars : Array[Node3D]
@export var RacerIcons : Array[TextureRect]
@onready var UI = $Minimap
@onready var Path = $Minimap/Minimap_road/Path2D
@onready var ItemIcon = $Minimap/Item_Visualizer/VBoxContainer/Item/ItemIcon
@onready var AltItemIcon = $Minimap/Item_Visualizer/VBoxContainer/AltItem/AltItemIcon
@onready var victorTime = $Finish_Line/finishline_delay

var doneRacers : Dictionary[int, int]

var yourAuthority : int
var youCar : Node3D

func _ready() -> void:
	$Minimap/Minimap_road/Line2D.clear_points()
	$Minimap/Minimap_road/Line2D2.clear_points()
	RacerIcons.clear()
	
	#HighLevelNetwork.end_race.connect(_on_all_done)
	
	yourAuthority = get_multiplayer_authority()
	HighLevelNetwork.attach_icon.connect(setup)
	
	for checkp in checkpoints:
		checkp.body_entered.connect(func(body):_on_checkpoint_crossed(checkp, body))
		pass

func setup(car : Node3D):
	Cars.append(car)
	print("kart attached to racetrack: "+ car.name)
	var racee = car.Racer.instantiate()
	var carIcon = racee.RacerIcon
	var racer: TextureRect = TextureRect.new()
	racer.name = car.name
	racer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	racer.texture = carIcon
	racer.size = Vector2(32, 32)
	racer.position = Path.curve.sample_baked(0.0) + Vector2(-16,-16)
	$Minimap/Minimap_road/Path2D.call_deferred("add_child", racer)
	RacerIcons.append(racer)
	if yourAuthority == car.player_id: 
		var rep = racee.RacerItem.instantiate()
		$Minimap/Item_Visualizer/VBoxContainer/AltItem/AltItemIcon.texture = rep.inventory_icon
		rep.queue_free()
	racee.queue_free()
	var pointCol = Path.curve.get_baked_points()
	for point in pointCol:
		$Minimap/Minimap_road/Line2D.add_point(point)
		$Minimap/Minimap_road/Line2D2.add_point(point)
	print(Cars.size())

func _process(_delta: float) -> void:
	if not (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled:
		return
	
	var prev_freed_cars = false
	
	for car in Cars:
		if car == null: 
			prev_freed_cars = true
			continue
		car.track_pos = get_track_placement(car.Ball.global_position, TrackPath)
		#print(car.track_pos)
		var indec = RacerIcons.find_custom(func(a): return car.name == a.name)
		var icon = RacerIcons[indec]
		icon.position = Path.curve.sample_baked(car.track_pos * Path.curve.get_baked_length()) + Vector2(-16,-16)
		#print(indec)
	
	if not prev_freed_cars:
		Cars.sort_custom(func(a, b): return a.track_pos + a.laps_made > b.track_pos + b.laps_made)
	
	for car in Cars:
		if car == null: continue
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
			$Minimap/Item_Visualizer/VBoxContainer/Item/ColorRect.visible = true
			$Minimap/Item_Visualizer/VBoxContainer/AltItem/ColorRect.visible = true
		else:
			$Minimap/Item_Visualizer/VBoxContainer/Item/ColorRect.visible = false
			$Minimap/Item_Visualizer/VBoxContainer/AltItem/ColorRect.visible = false
		
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

func update_lapcount(checkpointers : Array[Area3D], lap_count : int) -> int:
	if (not multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		return -1
	#print(str(checkpoints == checkpointers))
	if checkpoints == checkpointers:
		$Minimap/NewLapAnimtd/Label2.text = String(str(lap_count + 1) + "/" + str(MAX_LAPS))
		return lap_count + 1
	$Minimap/NewLapAnimtd/Label2.text = String(str(lap_count) + "/" + str(MAX_LAPS))
	return -1

func get_track_placement(global_loc : Vector3, path : Path3D) -> float:
	var curvy = path.curve
	var curv_space_pos = global_loc - path.global_position
	return curvy.get_closest_offset(curv_space_pos) / curvy.get_baked_length()
	#return ((curvy.get_baked_points().find(curvy.get_closest_point(curv_space_pos))) / curvy.get_baked_length()) + curvy.get_closest_offset(curv_space_pos)

func _on_checkpoint_crossed(checkpoint : Area3D, kart : Node3D):
	if not HighLevelNetwork.get_hosting(): 
		return
	#print("checkpoint crossed")
	
	if kart.name != "Ball":
		return
	
	if kart.get_parent().crossed_checkpoints.find(checkpoint) == -1:
		checkpoint.passed_cars.append(kart)
		kart.get_parent().crossed_checkpoints.append(checkpoint)
	pass

func _on_finish_line_body_entered(boddy: Node3D) -> void:
	if (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		var body = boddy.get_parent()
		if body.has_node("CarParent_Logic"):
			
			var updatd_lap_count = update_lapcount(body.crossed_checkpoints, body.laps_made)
			print(updatd_lap_count)
			if updatd_lap_count == -1:
				finish_line.missed_lap(body)
				print("%s missed a lap" % body.name)
				return
			else:
				body.crossed_checkpoints.clear()
				for checkp in checkpoints:
					checkp.passed_cars.erase(body)
				body.laps_made = updatd_lap_count
				
				if body.player_id != yourAuthority:
					if body.laps_made >= MAX_LAPS:
						finish_line.finished_race(body)
					return
				else:
					youCar = body
				
				if body.laps_made >= MAX_LAPS:
					animplayer.play("VICTORY")
				else:
					if body.laps_made == MAX_LAPS - 1:
						animplayer.play("Final Lap")
					else:
						animplayer.play("New Lap")
				print("%s lapped" % body.name)

func _on_all_done(id : int, score : int):
	if HighLevelNetwork.get_hosting():
		doning.rpc(id, score)

@rpc("call_local")
func doning(id : int, score : int):
	var bogo = doneRacers.get_or_add(id, score)
	if bogo == score:
		HighLevelNetwork.end_race.emit(id, score)
		print(str(Cars.size()) + " <=> " + str(doneRacers.size()))
		if doneRacers.size() >= Cars.size():
			print("start victortime!")
			UI.visible = false
			victorTime.start(2)

func _on_finishline_delay_timeout() -> void:
	print("exit race!")
	HighLevelNetwork.exit_race.emit()

func _on_new_lap_animation_finished(_anim_name: StringName) -> void:
	
	if youCar.laps_made >= MAX_LAPS:
		finish_line.finished_race(youCar)
