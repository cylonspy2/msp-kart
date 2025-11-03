extends Node3D

@export var caster : Node3D
@export var leaderboard_max : float
@export var leaderboard_min : float
@export var inventory_icon : Texture

@onready var ItemEffect = $ItemEffect

@export var job_done = false

func _ready():
	job_done = false

func _process(_delta: float) -> void:
	if job_done:
		despawn_item()

func define_caster(spawner : Node3D):
	caster = spawner

func cast_item():
	ItemEffect.activation()

func despawn_item():
	queue_free()
