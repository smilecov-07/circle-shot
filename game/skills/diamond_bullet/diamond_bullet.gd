extends Skill


@export var projectile_scene: PackedScene
@export var spread_base := 1.0
@export var spread_walk := 3.0
@export_range(0.0, 1.0) var spread_walk_ratio := 0.3

@onready var _aim: Line2D = $Aim
@onready var _spread_left: Line2D = $Aim/SpreadLeft
@onready var _spread_right: Line2D = $Aim/SpreadRight


func _process(_delta: float) -> void:
	if _player.is_local() \
			and _player.player_input.shooting_started.is_connected(_on_player_shooting_started):
		_aim.rotation = _player.player_input.aim_direction.angle()
		_aim.visible = _player.player_input.showing_aim
		
		_spread_left.rotation_degrees = -_calculate_spread()
		_spread_right.rotation_degrees = _calculate_spread()


func _use() -> void:
	($ActiveMarker/AnimationPlayer as AnimationPlayer).play(&"Active")
	_player.player_input.shooting_started.connect(_on_player_shooting_started, CONNECT_ONE_SHOT)


func _can_use() -> bool:
	return is_instance_valid(_player.current_weapon) \
			and not _player.player_input.shooting_started.is_connected(_on_player_shooting_started)


func _calculate_spread() -> float:
	return spread_walk * clampf((_player.entity_input.direction.length() - spread_walk_ratio)
			/ (1.0 - spread_walk_ratio), 0.0, 1.0) + spread_base


func _on_player_shooting_started() -> void:
	($ActiveMarker/AnimationPlayer as AnimationPlayer).play(&"RESET")
	if multiplayer.is_server() and not _player.is_disarmed():
		var projectile: Projectile = projectile_scene.instantiate()
		projectile.position = _player.position + 64 * Vector2.from_angle(
				_player.player_input.aim_direction.angle())
		projectile.damage_multiplier = _player.damage_multiplier
		var spread: float = deg_to_rad(_calculate_spread())
		projectile.rotation = _player.player_input.aim_direction.angle() \
				+ randf_range(-spread, spread)
		projectile.team = _player.team
		projectile.who = _player.id
		projectile.name += str(randi())
		_other_parent.add_child(projectile)
	
	if _player.is_local():
		_aim.hide()
