extends PlayerSkin


func _initialize() -> void:
	player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(old: int, new: int) -> void:
	if old > new:
		($AnimationPlayer as AnimationPlayer).play(&"Hurt")
		($AnimationPlayer as AnimationPlayer).seek(0.0, true)
