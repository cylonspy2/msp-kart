extends Control

@export var labell : Label
@export var labShad : Label
var centerShadow : Vector2
@export var pointy : Vector2 = Vector2(0.0, 2.0)
@export var speed : float = 1
func _ready() -> void:
	centerShadow = labShad.position

func _process(_delta: float) -> void:
	pointy = pointy.rotated(deg_to_rad(speed))
	labShad.position = centerShadow + pointy
