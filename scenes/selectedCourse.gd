extends VBoxContainer

@onready var namee = $Label2
@onready var texture = $TextureRect

func _ready() -> void:
	HighLevelNetwork.select_track.connect(func(id) : update_button(id))

func update_button(track : PackedScene):
	var trac = track.instantiate()
	namee.text = trac.name
	texture.texture = trac.map_icon
	trac.queue_free()
