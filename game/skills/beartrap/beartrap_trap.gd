extends Attack

@export var stun_duration := 1.5
@export var slowdown_duration := 4.0
@export var slowdown_multiplier := 0.7

func _ready() -> void:
	if (get_tree().get_first_node_in_group(&"Event") as Event).local_team == team:
		($AnimationPlayer as AnimationPlayer).play(&"PlaceFriendly")
	else:
		($AnimationPlayer as AnimationPlayer).play(&"Place")


func _deal_damage(entity: Entity) -> void:
	entity.add_effect.rpc(Effect.STUN, stun_duration)
	entity.add_effect.rpc(Effect.SPEED_CHANGE, slowdown_duration, [slowdown_multiplier])
	($AreaDetector/CollisionShape2D as CollisionShape2D).disabled = true
	_show_trapped.rpc(entity.position + Vector2.DOWN * 40)


@rpc("reliable", "authority", "call_local", 5)
func _show_trapped(at_position: Vector2) -> void:
	($AnimationPlayer as AnimationPlayer).play(&"Trapped")
	position = at_position


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"Trapped" and multiplayer.is_server():
		queue_free()
