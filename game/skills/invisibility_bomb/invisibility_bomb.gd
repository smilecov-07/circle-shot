extends Skill

@export var duration := 4.0
var _use_effect_scene: PackedScene = preload("uid://7yeuewjt5nf4")
@onready var _timer: Timer = $Timer

func _use() -> void:
	block_cooldown()
	var use_effect: Node2D = _use_effect_scene.instantiate()
	player.visual.add_child(use_effect)
	_timer.start(0.5)
	await _timer.timeout
	if multiplayer.is_server():
		player.add_effect.rpc(Effect.INVISIBILITY, duration)
	_timer.start(duration)
	await _timer.timeout
	unblock_cooldown()
