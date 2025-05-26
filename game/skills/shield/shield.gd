extends Skill


@export_range(0.0, 0.99, 0.01) var protection := 0.5
@export_range(0.0, 0.99, 0.01) var slowdown := 0.3
@export var duration := 3.5

@onready var _timer: Timer = $Timer


func _use() -> void:
	block_cooldown()
	($AnimationPlayer as AnimationPlayer).play(&"Use")
	
	if multiplayer.is_server():
		player.add_effect.rpc(Effect.DEFENSE_CHANGE, duration, [1.0 - protection])
		player.add_effect.rpc(Effect.SPEED_CHANGE, duration, [1.0 - slowdown])
	
	_timer.start(duration)
	await _timer.timeout
	
	unblock_cooldown()
