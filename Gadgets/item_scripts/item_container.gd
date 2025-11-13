extends Node3D

@onready var collideShape = $Collider/CollisionShape3D

@export var fullUp = true
@export var has_popped = false
@export var readyToRespawn = false

func _process(_delta: float) -> void:
	if readyToRespawn:
		respawn()
		fullUp = true
		readyToRespawn = false
	if fullUp and has_popped:
		pop()
		has_popped = false
		fullUp = false

func pop():
	$Container.visible = false
	$AnimationPlayer.play("pop")
	$Collider.process_mode = Node.PROCESS_MODE_DISABLED
	$RestockTimer.start()

func respawn():
	$Container.visible = true
	$AnimationPlayer.play("respawn")
	$Collider.process_mode = Node.PROCESS_MODE_INHERIT


func _on_restock_timer_timeout() -> void:
	readyToRespawn = true
	print("readytorespawn")


func _on_collider_body_entered(body: Node3D) -> void:
	print("item box hit! " + str(body.name))
	if not HighLevelNetwork.get_hosting(): 
		##client deferring to server data
		pass
	else:
		if body.has_node("Car_Marker"):
			has_popped = true
			var item = HighLevelNetwork._grab_item(body.parentCar.leaderboard_placement)
			update_item_lobbywide.rpc(body, item)

@rpc("call_local")
func update_item_lobbywide(body: Node3D, item : PackedScene):
	body.parentCar.gainItem.emit(item)
	print(item)
