extends Effect


func _start_effect() -> void:
	entity.knockback += data[0]
	entity.make_immobile()


func _end_effect() -> void:
	entity.knockback -= data[0]
	entity.unmake_immobile()
