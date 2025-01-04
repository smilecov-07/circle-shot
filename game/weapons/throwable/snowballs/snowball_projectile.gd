extends Projectile

@export var slowdown_duration := 1.5
@export_range(0.1, 1.0, 0.01) var speed_multiplier := 0.65

func _deal_damage(entity: Entity) -> void:
	entity.add_effect.rpc(Effect.SPEED_CHANGE, slowdown_duration, [speed_multiplier])
