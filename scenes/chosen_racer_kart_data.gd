extends HBoxContainer

@onready var namee = $Label2
@onready var texture = $TextureRect

func _ready() -> void:
	HighLevelNetwork.select_kart.connect(func(id) : update_kart(id))
	HighLevelNetwork.select_racer.connect(func(id) : update_racer(id))

func update_kart(track : PackedScene):
	var trac = track.instantiate()
	namee.text = trac.name
	texture.texture = trac.map_icon
	trac.queue_free()

func update_racer(track : PackedScene):
	var trac = track.instantiate()
	namee.text = trac.name
	texture.texture = trac.map_icon
	trac.queue_free()
