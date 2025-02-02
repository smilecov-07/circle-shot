extends Skill

@export var projectile_scene: PackedScene
@onready var _aim: Line2D = $Aim

func _process(_delta: float) -> void:
	if _player.is_local() \
			and _player.player_input.shooting_started.is_connected(_on_player_shooting_started):
		_aim.rotation = _player.player_input.aim_direction.angle()
		_aim.visible = _player.player_input.showing_aim


func _use() -> void:
	($ActiveMarker/AnimationPlayer as AnimationPlayer).play(&"Active")
	_player.player_input.shooting_started.connect(_on_player_shooting_started, CONNECT_ONE_SHOT)


func _can_use() -> bool:
	return is_instance_valid(_player.current_weapon) \
			and not _player.player_input.shooting_started.is_connected(_on_player_shooting_started)


func _on_player_shooting_started() -> void:
	($ActiveMarker/AnimationPlayer as AnimationPlayer).play(&"RESET")
	if multiplayer.is_server():
		var projectile: Projectile = projectile_scene.instantiate()
		projectile.position = _player.position
		projectile.damage_multiplier = _player.damage_multiplier
		projectile.rotation = _player.player_input.aim_direction.angle()
		projectile.team = _player.team
		projectile.who = _player.id
		projectile.name += str(randi())
		_other_parent.add_child(projectile)
	
	if _player.is_local():
		_aim.hide()
