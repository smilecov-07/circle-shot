extends Effect


func _start_effect() -> void:
	if data.size() != 1:
		queue_free()
		return
	var multiplier: float = data[0]
	if is_zero_approx(multiplier):
		entity.make_immune()
		# TODO: мб добавить особую анимку
	else:
		entity.defense_multiplier *= multiplier
	if multiplier > 1.0:
		($Down as CanvasItem).show()
		negative = true
	elif multiplier < 1.0:
		($Bubble/AnimationPlayer as AnimationPlayer).play(&"Shield")


func _end_effect() -> void:
	var multiplier: float = data[0]
	if is_zero_approx(multiplier):
		entity.unmake_immune()
	else:
		entity.defense_multiplier /= multiplier
