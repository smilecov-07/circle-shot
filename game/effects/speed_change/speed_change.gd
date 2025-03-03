extends Effect


func _start_effect() -> void:
	if data.size() != 1:
		queue_free()
		return
	var multiplier: float = data[0]
	entity.speed_multiplier *= multiplier
	if multiplier > 1.0:
		($Speedup as CanvasItem).show()
	elif multiplier < 1.0:
		($Slowdown as CanvasItem).show()
		negative = true


func _end_effect() -> void:
	var multiplier: float = data[0]
	entity.speed_multiplier /= multiplier
