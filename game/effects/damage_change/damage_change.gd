extends Effect


func _start_effect() -> void:
	if data.size() != 1:
		queue_free()
		return
	var multiplier: float = data[0]
	entity.damage_multiplier *= multiplier
	if multiplier > 1.0:
		($Up as CanvasItem).show()
	elif multiplier < 1.0:
		($Down as CanvasItem).show()
		negative = true


func _end_effect() -> void:
	var multiplier: float = data[0]
	entity.damage_multiplier /= multiplier
