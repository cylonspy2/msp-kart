extends HBoxContainer

@onready var namekart = $Kart/VBoxContainer/Names/Label
@onready var nameracer = $Kart/VBoxContainer/Names/Label2
@onready var subViewie = $Kart/VBoxContainer/SubViewportContainer/SubViewport
@onready var stat_weight = $Stats/STATS/Weight
@onready var stat_maxspeed = $Stats/STATS/MaxSpd
@onready var stat_accel = $Stats/STATS/Acceleration
@onready var stat_steer = $Stats/STATS/Steering
@onready var stat_drift = $"Stats/STATS/Drift Control"
@onready var stat_drift_accel = $Stats/STATS/Drift
@onready var stat_drift_steer = $"Stats/STATS/Drift Steer"
@onready var stat_boost = $Stats/STATS/Boost
@onready var stat_air_control = $Stats/STATS/AirControl
@onready var skill_item = $Control/VBoxContainer/ColorRect/Item
var kartChosen : Node3D
var kartChosenScene : PackedScene
var racerChosen : PackedScene
@export var placeholderRacer : PackedScene
@export var placeholderKart : PackedScene

func _ready() -> void:
	HighLevelNetwork.select_kart.connect(func(id) : update_kart(id))
	HighLevelNetwork.select_racer.connect(func(id) : update_racer(id))
	HighLevelNetwork.enter_race.connect(clear_out)

func clear_out():
	kartChosen.queue_free()
	for nodd : Node3D in subViewie.get_children():
		nodd.visible = false
		if nodd.name == "CSGBox3D":
			nodd.use_collision = false

func update_kart(track : PackedScene):
	if track == null:
		track = placeholderKart
	for nodd : Node3D in subViewie.get_children():
		if nodd.name != "CSGBox3D":
			nodd.visible = true
		else:
			nodd.use_collision = true
	if track == null:
		return
	kartChosenScene = track
	if kartChosen != null:
		kartChosen.queue_free()
	var trac = track.instantiate()
	trac.get_child(2).get_child(0).get_child(6).queue_free()
	trac.get_child(2).get_child(0).get_child(0).queue_free()
	trac.get_child(0).get_child(1).racing = false
	
	if racerChosen == null:
		trac.Racer = placeholderRacer
	else:
		trac.Racer = racerChosen
	subViewie.call_deferred("add_child", trac)
	kartChosen = trac
	namekart.text = trac.name
	trac.player_id = -20
	stat_weight.value = kartChosen.weight
	stat_accel.value = kartChosen.acceleration
	var bluh = kartChosen.steering
	var driftAmount = bluh * kartChosen.steeringDrift
	stat_steer.value = bluh + lerp(bluh, driftAmount, kartChosen.turnspeed)
	stat_drift.value = kartChosen.steeringAccelMod
	stat_drift_steer.value = stat_steer.value - kartChosen.drift_steering
	stat_boost.value = kartChosen.driftBoost + kartChosen.initial_driftBoost
	stat_drift_accel.value = kartChosen.drift_acceleration
	stat_air_control.value = kartChosen.airControl
	stat_maxspeed.value = kartChosen.maxSpeed

func update_racer(track : PackedScene):
	if track == null:
		track = placeholderRacer
	racerChosen = track
	update_kart(kartChosenScene)
	var trac = track.instantiate()
	var raceItem = trac.RacerItem.instantiate()
	skill_item.texture = raceItem.inventory_icon
	raceItem.queue_free()
	nameracer.text = trac.name
	trac.queue_free()
