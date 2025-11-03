extends Node3D

@onready var parent = $".."

func activation():
	parent.job_done = true
