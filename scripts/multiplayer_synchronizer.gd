extends MultiplayerSynchronizer

@onready var Car = $"../.."

@export var inputDir : float
@export var inputRot : float

var haveAuthority = false

func _ready() -> void:
	if get_multiplayer_authority() != Car.player_id: 
		haveAuthority = false
		set_process(false)
		set_physics_process(false)
	else : 
		haveAuthority = true
	
	inputDir = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
	inputRot = Input.get_action_strength("SteerLeft") - Input.get_action_strength("SteerRight")

func _process(delta: float) -> void:
	if not haveAuthority: return
	inputDir = Input.get_action_strength("Accelerate") - Input.get_action_strength("Brake")
	inputRot = Input.get_action_strength("SteerLeft") - Input.get_action_strength("SteerRight")
	if HighLevelNetwork.multiplayer_enabled:
		if Input.is_action_just_pressed("Drift"):
			drift.rpc()
		if Input.is_action_just_released("Drift"):
			off_drift.rpc()
		if Input.is_action_just_pressed("Fire"):
			item_used.rpc()
		if Input.is_action_just_pressed("Altfire"):
			ability_used.rpc()
	else:
		Car.start_drift = Input.is_action_just_pressed("Drift")
		Car.end_drift = Input.is_action_just_released("Drift")
		Car.firedItem = Input.is_action_just_pressed("Fire")
		Car.altFiredItem = Input.is_action_just_pressed("Altfire")

@rpc("call_local")
func drift():
	if multiplayer.server() or haveAuthority:
		Car.start_drift = true

@rpc("call_local")
func off_drift():
	if multiplayer.server() or haveAuthority:
		Car.end_drift = true

@rpc("call_local")
func item_used():
	if multiplayer.server() or haveAuthority:
		Car.firedItem = true

@rpc("call_local")
func ability_used():
	if multiplayer.server() or haveAuthority:
		Car.altFiredItem = true
