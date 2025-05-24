class_name Grenade
extends Weapon

## Узел оружия класса "Гранаты".

## Сцена снаряда типа [GrenadeProjectile].
@export var projectile_scene: PackedScene
## Базовый разброс снаряда.
@export var spread_base := 1.0
## На сколько повысится разброс снаряда при ходьбе.
@export var spread_walk := 5.0
## Множитель для определения максимальной скорости, при которой разброс
## при движении не будет добавляться.
@export_range(0.0, 1.0) var spread_walk_ratio := 0.5
## Скорость снаряда гранаты. Используется для линии прицела.
@export var projectile_speed := 800.0
## Замедление снаряда гранаты. Используется для линии прицела.
@export var projectile_damping := 200.0
## Время, через которое взорвётся снаряд. Используется для линии прицела.
@export var projectile_explosion_time := 2.5

var _reloading := false

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _throw_point: Marker2D = $ThrowPivot/ThrowPoint
@onready var _throw_pivot: Marker2D = $ThrowPivot

@onready var _aim: Line2D = $ThrowPivot/ThrowPoint/Aim
@onready var _aim_outline: Line2D = $ThrowPivot/ThrowPoint/Aim/Outline
@onready var _aim_spread_left: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadLeft
@onready var _aim_spread_right: Line2D = $ThrowPivot/ThrowPoint/Aim/SpreadRight


func _process(_delta: float) -> void:
	_aim.hide()
	
	if can_shoot():
		_aim.visible = player.player_input.showing_aim
		_throw_pivot.rotation = _calculate_aim_angle()
		
		var spread: float = _calculate_spread()
		_aim_spread_left.rotation_degrees = -spread
		_aim_spread_right.rotation_degrees = spread
		
		# Вычисление длины пути гранаты через формулу по физике xD
		var speed_multiplier: float = player.player_input.aim_direction.length()
		var time: float = minf(projectile_speed * speed_multiplier / projectile_damping,
				projectile_explosion_time)
		var distance: float = projectile_speed * time * speed_multiplier \
				- projectile_damping / 2 * time * time
		_aim.points[1].x = distance
		_aim_outline.points[1].x = distance


func _physics_process(_delta: float) -> void:
	if can_shoot() and multiplayer.is_server() and player.player_input.shooting \
			and ammo_in_stock > 0 and not _reloading:
		shoot([player.player_input.aim_direction])


func _make_current() -> void:
	if ammo_in_stock > 0 and not _reloading:
		_anim.play(&"Equip")
		block_shooting()
		await _anim.animation_finished
		unblock_shooting()


func _unmake_current() -> void:
	_anim.play(&"RESET")
	_anim.advance(0.01)


func _shoot(throw_direction := Vector2.ZERO) -> void:
	block_shooting()
	player.block_turning()
	player.visual.scale.x = -1.0 if throw_direction.x < 0.0 else 1.0
	_anim.play(&"Throw")
	var anim_name: StringName = await _anim.animation_finished
	if anim_name != &"Throw":
		player.unblock_turning()
		unblock_shooting()
		return
	
	var animation: Animation = _anim.get_animation(&"PostThrow")
	animation.track_set_key_value(0, 0, _throw_pivot.position)
	animation.track_set_key_value(0, 1, to_local(_throw_point.global_position))
	_anim.play(&"PostThrow")
	anim_name = await _anim.animation_finished
	player.unblock_turning()
	if anim_name != &"PostThrow":
		unblock_shooting()
		return
	
	ammo_in_stock -= 1
	_reloading = true
	($ThrowTimer as Timer).start()
	
	if multiplayer.is_server():
		var projectile: GrenadeProjectile = projectile_scene.instantiate()
		projectile.position = _throw_point.global_position
		var spread: float = deg_to_rad(_calculate_spread())
		projectile.direction = throw_direction.normalized().rotated(randf_range(-spread, spread))
		projectile.speed *= minf(throw_direction.length(), 1.0)
		_customize_projectile(projectile)
		projectile.name += str(randi())
		_projectiles_parent.add_child(projectile)
	
	_unmake_current()


func _can_reload() -> bool:
	return false


func get_ammo_text() -> String:
	return "Осталось: %d" % ammo_in_stock


func _calculate_spread() -> float:
	return spread_walk * clampf((player.entity_input.direction.length() - spread_walk_ratio)
			/ (1.0 - spread_walk_ratio), 0.0, 1.0) + spread_base


## Переопределите, чтобы настроить [GrenadeProjectile] до добавления его в дерево сцены.
func _customize_projectile(_projectile: GrenadeProjectile) -> void:
	pass


func _on_throw_timer_timeout() -> void:
	_reloading = false
	unblock_shooting()
	if player.current_weapon == self:
		_make_current()
