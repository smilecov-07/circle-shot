extends Effect


func _start_effect() -> void:
	entity.make_immobile()


func _end_effect() -> void:
	entity.unmake_immobile()
