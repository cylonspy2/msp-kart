extends Node3D

@onready var collideShape = $Collider/CollisionShape3D

@export var fullUp = true
@export var popped = false
@export var readyToRespawn = false

func _process(delta: float) -> void:
	if readyToRespawn:
		respawn()
		fullUp = true
		popped = false
		readyToRespawn = false
	if fullUp and popped:
		pop()
		popped = true
		fullUp = false

func pop():
	$Container.enabled = false
	$AnimationPlayer.play("pop")
	$Collider.process_mode = Node.PROCESS_MODE_DISABLED


func respawn():
	$Collider.process_mode = Node.PROCESS_MODE_INHERIT
	$Container.enabled = false
	$AnimationPlayer.play("respawn")


func _on_restock_timer_timeout() -> void:
	readyToRespawn = true


func _on_collider_body_entered(body: Node3D) -> void:
	print("item box hit! " + str(body.name))
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		if body.has_node("Car_Marker"):
			popped = true
			body.parentCar.gainItem.emit(HighLevelNetwork._grab_item(body.parentCar.leaderboard_placement))
			
