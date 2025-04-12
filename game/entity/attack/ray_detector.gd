class_name RayDetector
extends RayCast2D
## Детектор в виде [RayCast2D] для [Attack].

## Издаётся, когда луч сталкивается с чем-то. [param where] содержит позицию столкновения,
## а [param what] - сущность, с которой луч столкнулся (может быть [code]null[/code],
## если столкновение было не с сущностью).
signal hit(where: Vector2, what: Entity)
@onready var _attack: Attack = get_parent()

func _ready() -> void:
	_attack.ray_detectors.append(self)


func _physics_process(delta: float) -> void:
	if is_colliding():
		var entity := get_collider() as Entity
		if entity:
			if entity.team == _attack.team:
				add_exception(entity)
				force_raycast_update()
				_physics_process(delta)
				return
			if _attack.can_deal_damage(entity):
				if multiplayer.is_server():
					_attack.deal_damage(entity)
				hit.emit(get_collision_point(), entity)
		else:
			hit.emit(get_collision_point(), null)


func _exit_tree() -> void:
	_attack.ray_detectors.erase(self)
