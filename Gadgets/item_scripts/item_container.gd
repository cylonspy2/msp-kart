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
	$Collider.process_mode = Node.PROCESS_MODE_DISABLED
	$Container.enabled = false
	$AnimationPlayer.play("pop")


func respawn():
	$Collider.process_mode = Node.PROCESS_MODE_INHERIT
	$Container.enabled = false
	$AnimationPlayer.play("respawn")


func _on_restock_timer_timeout() -> void:
	readyToRespawn = true


func _on_collider_body_entered(body: Node3D) -> void:
	if (not multiplayer.is_server() or HighLevelNetwork.host_mode_enabled) and HighLevelNetwork.multiplayer_enabled: 
		##client deferring to server data
		pass
	else:
		if body.has_node("CarParent_Logic"):
			popped = true
			body.itemHeld = HighLevelNetwork._grab_item(body.leaderboard_placement)
			body.hasItem = true
			body.gainItem.emit()
			pass
		pass
