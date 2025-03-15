extends Skill

@export var trap_scene: PackedScene
var _use_effect_scene: PackedScene = preload("uid://dxfkmwyd21cng")

func _use() -> void:
	var use_effect: Node2D = _use_effect_scene.instantiate()
	player.visual.add_child(use_effect)
	if multiplayer.is_server():
		($PlaceTimer as Timer).start()


func _on_place_timer_timeout() -> void:
	var trap: Attack = trap_scene.instantiate()
	trap.position = player.position
	trap.position.y += 40
	trap.team = player.team
	trap.who = player.id
	trap.damage_multiplier = player.damage_multiplier
	_other_parent.add_child(trap, true)
