extends Effect


func _start_effect() -> void:
	_entity.knockback += _data[0]
	_entity.make_immobile()


func _end_effect() -> void:
	_entity.knockback -= _data[0]
	_entity.unmake_immobile()
