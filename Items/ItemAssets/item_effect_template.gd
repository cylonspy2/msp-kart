extends Node3D

@export var parent : Node3D

func activation():
	parent.job_done = true

func ready_up():
	pass
