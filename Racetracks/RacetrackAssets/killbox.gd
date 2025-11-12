extends Area3D

@onready var parrent = $"../.."
@export var master_path : Path3D
@export var true_paths : Array[Path3D]
@export var CarContainer : Node3D
@export var drop_height : float = 9

func _on_body_entered(body: Node3D) -> void:
	if body.get_parent().get_child(0).name == "CarParent_Logic":
		print("%s fell" % body.get_parent().name)
		body.get_parent().hasControl = false
		var timee = Timer.new()
		var idd = body.get_parent().name
		get_parent().add_child(timee)
		timee.name = idd
		timee.timeout.connect(func() : _on_finished_timer(idd))
		timee.one_shot = true
		timee.start(2)

func _on_finished_timer(naeme : String):
	if (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) or not HighLevelNetwork.multiplayer_enabled:
		print(naeme)
		var things = CarContainer.get_children()
		for itemn in things:
			var item
			if itemn.get_child_count() >= 2:
				item = itemn.get_child(1)
				var TrackPath_pos = item.track_pos
				var master_end_pos = master_path.curve.sample_baked_with_rotation(TrackPath_pos * master_path.curve.get_baked_length())
				var true_end_pos :Transform3D = master_end_pos
				var true_end_rot :Vector3 = Vector3(0.0, 1.0, 0.0)
				var tru_path : Path3D = master_path
				for path : Path3D in true_paths :
					var potent_pos = parrent.get_track_placement(item.Ball.global_position, path)
					var potential_end_pos = path.curve.sample_baked_with_rotation(potent_pos * path.curve.get_baked_length(), false, true)
					var potential_end_rot = path.curve.sample_baked_up_vector(potent_pos * path.curve.get_baked_length(), true)
					if potential_end_pos.origin - master_end_pos.origin <= true_end_pos.origin - master_end_pos.origin:
						true_end_pos = potential_end_pos
						true_end_rot = potential_end_rot
						tru_path = path
				var struth = true_end_pos.basis.rotated(true_end_pos.basis.y, deg_to_rad(180))
				item.Ball.global_position = true_end_pos.origin + tru_path.global_position + (Vector3(0.0, drop_height, 0.0) * (struth))
				item.Car.global_position = item.Ball.global_position
				item.Car.global_basis = struth
				#item.Car.global_basis.y = true_end_rot
				item.Ball.move_and_collide(-struth.y * drop_height)
				item.gravForce = -item.Car.global_basis.y
				print(item.name + " " + str((Vector3(0.0, drop_height, 0.0) * (struth))))
				item._recover()
				return
			#print(itemn.name)
	else:
		print("wait, what?")
