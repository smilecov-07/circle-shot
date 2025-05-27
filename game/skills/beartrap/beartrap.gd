extends Skill

@export var trap_scene: PackedScene
var _use_effect_scene: PackedScene = preload("uid://dxfkmwyd21cng")

func _use() -> void:
	var use_effect: Node2D = _use_effect_scene.instantiate()
	player.visual.add_child(use_effect)
	block_cooldown()
	($PlaceTimer as Timer).start()


func _on_place_timer_timeout() -> void:
	unblock_cooldown()
	if not multiplayer.is_server():
		return
	var trap: Attack = trap_scene.instantiate()
	trap.position = player.position
	trap.position.y += 40
	trap.team = player.team
	trap.who = player.id
	trap.damage_multiplier = player.damage_multiplier
	_other_parent.add_child(trap, true)


func _player_disarmed() -> void:
	if player.visual.has_node(^"UseEffect"):
		player.visual.get_node(^"UseEffect").process_mode = Node.PROCESS_MODE_DISABLED
	($PlaceTimer as Timer).paused = true


func _player_armed() -> void:
	if player.visual.has_node(^"UseEffect"):
		player.visual.get_node(^"UseEffect").process_mode = Node.PROCESS_MODE_INHERIT
	($PlaceTimer as Timer).paused = false
