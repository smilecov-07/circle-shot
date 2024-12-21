class_name EntityInput
extends MultiplayerSynchronizer
## Узел с вводом для сущности.

## Направление движения сущности.
var direction := Vector2():
	set(value):
		if not value.is_finite():
			direction = Vector2.ZERO
		elif value.length_squared() > 1.0:
			direction = value.limit_length(1.0)
		else:
			direction = value
