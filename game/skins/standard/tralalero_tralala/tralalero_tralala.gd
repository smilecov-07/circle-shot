extends PlayerSkin

@onready var _anim: AnimationPlayer = $AnimationPlayer

func _process(_delta: float) -> void:
	if player.entity_input.direction.is_zero_approx():
		if _anim.current_animation == "Walk":
			_anim.play(&"Idle")
			_anim.speed_scale = 1.0
	else:
		if _anim.current_animation == "Idle":
			_anim.play(&"Walk")
		_anim.speed_scale = player.entity_input.direction.length()
