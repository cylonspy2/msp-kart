extends Node3D

@onready var parrent : Node3D = $"../../../.."
@export var sparkMat : BaseMaterial3D
@export var base_color : Color
@export var tier_1_color : Color
@export var tier_2_color : Color
@export var tier_3_color : Color
@export var tier_4_color : Color
@export var sparks : Array[GPUParticles3D]

var renderable = true

func _ready() -> void:
	if (multiplayer.is_server() and not HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled:
		renderable = false
		return
	for sparky : GPUParticles3D in sparks:
		sparky.emitting = false

func _process(delta: float) -> void:
	if renderable:
		return
	if parrent.start_drift:
		for sparky : GPUParticles3D in sparks:
			sparky.emitting = true
	if parrent.drifting:
		match parrent.boostTiering:
			1:
				sparkMat.albedo_color = tier_1_color
				sparkMat.emission = tier_1_color
			2:
				sparkMat.albedo_color = tier_2_color
				sparkMat.emission = tier_2_color
			3:
				sparkMat.albedo_color = tier_3_color
				sparkMat.emission = tier_3_color
			4:
				sparkMat.albedo_color = tier_4_color
				sparkMat.emission = tier_4_color
			_:
				sparkMat.albedo_color = base_color
				sparkMat.emission = base_color
	if parrent.end_drift:
		for sparky : GPUParticles3D in sparks:
			sparky.emitting = false
