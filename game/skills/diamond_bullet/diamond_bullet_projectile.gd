extends Projectile

@export var knockback_power := 1280.0
@export var knockback_duration := 0.5

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property($Trail as Node2D, ^":scale:x", 1.0, 0.4).from(0.1)
	tween.custom_step(0.01)
	super()


func _deal_damage(entity: Entity) -> void:
	entity.add_effect.rpc(Effect.KNOCKBACK, knockback_duration,
			[knockback_power * Vector2.from_angle(rotation)])
