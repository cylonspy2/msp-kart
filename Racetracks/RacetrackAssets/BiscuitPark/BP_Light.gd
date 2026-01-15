extends DirectionalLight3D

@export var parr : Node3D

func _process(_delta: float) -> void:
	global_basis = parr.youCar.Car.global_basis.rotated(parr.youCar.Car.global_basis.x, deg_to_rad(-90))
