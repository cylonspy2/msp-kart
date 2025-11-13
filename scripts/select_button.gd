extends Control

@export var type : int
@export var object : PackedScene


func _on_button_pressed() -> void:
	match (type):
		0:
			HighLevelNetwork.select_track.emit(object)
		1:
			HighLevelNetwork.select_kart.emit(object)
		2:
			HighLevelNetwork.select_racer.emit(object)
