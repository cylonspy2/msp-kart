extends Node3D

signal despawn

@export var caster : Node3D
@export var leaderboard_max : float
@export var leaderboard_min : float
@export var inventory_icon : Texture

@onready var ItemEffect = $ItemEffect

func _enter_tree() -> void:
	despawn.connect(despawn_item)

func define_caster(spawner : Node3D):
	caster = spawner

func cast_item():
	pass

func despawn_item():
	pass
