extends Node3D

@export var parent : Node3D
@export var partSys : GPUParticles3D
@export var boostTime : Timer

@export var baseBonus : int = 2
@export var friendshipBonus : float = 1.0

func activation():
	if parent.caster.haveAuthority:
		partSys.restart(false)
		global_position = parent.caster.RacerSpawnLoc.global_position
		global_rotation = parent.caster.RacerSpawnLoc.global_rotation
		partSys.emitting = true
	if not HighLevelNetwork.get_hosting():
		return
	parent.caster.boostTiering += baseBonus + ((HighLevelNetwork._get_player_count() - parent.caster.leaderboard_placement) * friendshipBonus)
	parent.caster.minimumDrift = true
	parent.caster.is_touching_ground = true
	if parent.caster.drifting:
		parent.caster.end_drift = false
		parent.caster.start_drift = false
		parent.caster.startedDrifting = false
		parent.caster.driftTimer.stop()
		parent.caster.drifting = false
	parent.caster.boostTimer.stop()
	parent.caster.StopDrift()
	boostTime.start(parent.caster.boostTimer.time_left + 0.5)

func _process(_delta: float) -> void:
	global_position = parent.caster.RacerSpawnLoc.global_position
	global_rotation = parent.caster.RacerSpawnLoc.global_rotation

func ready_up():
	partSys.emitting = false
	parent.cast_item()

func _on_boost_time_timeout() -> void:
	parent.job_done = true
