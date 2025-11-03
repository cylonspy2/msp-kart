extends Node3D

@export var strength = 1.0
@onready var parent = $".."
@onready var anim = $AnimationPlayer
@onready var hitbox = $Area3D/CollisionShape3D

func _ready() -> void:
	hitbox.disabled = true

func activation():
	
	if (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled):
		global_position = parent.caster.global_position
		global_rotation = parent.caster.global_rotation
		hitbox.disabled = false
	anim.play("HONK")

func _process(_delta: float) -> void:
	global_position = parent.caster.global_position
	global_rotation = parent.caster.global_rotation

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if (multiplayer.is_server() or HighLevelNetwork.host_mode_enabled):
		hitbox.disabled = true
		parent.job_done = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body != parent.caster.CarHitBox:
		body.GetHit(strength)
