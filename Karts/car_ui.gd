extends Control

@export var ranking : int = 0
@export var item_slot : Texture
@export var altitem_slot : Texture

func _ready() -> void:
	visible = true
	mouse_filter = MOUSE_FILTER_PASS
	HighLevelNetwork.end_race.connect(close_racer_ui)

func close_racer_ui():
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	pass
