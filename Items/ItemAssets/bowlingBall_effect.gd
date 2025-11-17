extends Node3D

@export var strength = 1.0
@export var parent : Node3D
@export var hitbox : CollisionShape3D
@export var ball : RigidBody3D
@export var anim : AnimationPlayer

var grav_dir
var spawn_pos

func _ready() -> void:
	#ball.visible = false
	parent.job_done = false
	hitbox.disabled = true

func activation():
	#ball.visible = true
	global_position = parent.caster.get_child(2).global_position
	spawn_pos = global_position
	global_rotation = parent.caster.get_child(2).global_rotation
	grav_dir = parent.caster.gravForce.normalized()
	print(global_position, " ", grav_dir)
	hitbox.disabled = false

func ready_up():
	parent.cast_item()

func _physics_process(_delta):
	ball.apply_impulse(grav_dir * 9.8)
	ball.apply_central_force((spawn_pos - global_position))

func _process(delta: float) -> void:
	pass

func _on_rigid_body_3d_body_entered(body: Node3D) -> void:
	if body.has_node("Car_Marker"):
		print("car hit")
		if body != parent.caster.CarHitBox:
			body.get_parent().get_parent().get_parent().Ball.linear_velocity = Vector3.ZERO
			body.get_parent().get_parent().get_parent().GetHit(strength)
			parent.job_done = true
		else:
			body.get_parent().get_parent().get_parent().Ball.linear_velocity = Vector3.ZERO
			body.get_parent().get_parent().get_parent().GetHit(strength)
			parent.job_done = true
