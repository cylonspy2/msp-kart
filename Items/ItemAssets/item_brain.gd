extends Node3D

@export var caster : Node3D
@export var leaderboard_max : float
@export var leaderboard_min : float
@export var inventory_icon : Texture

@export var ItemEffect : Node3D

@export var job_done = false

func _ready():
	job_done = false
	ItemEffect.ready_up()

func _process(_delta: float) -> void:
	if job_done:
		despawn_item()

func define_caster(spawner : Node3D):
	caster = spawner

func cast_item():
	print(ItemEffect)
	ItemEffect.activation()

func despawn_item():
	queue_free()
