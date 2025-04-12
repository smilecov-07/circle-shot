class_name Projectile
extends Attack

## Снаряд.
##
## Базовый класс для атаки, летящей в определённом направлении.[br]
## [b]Заметка[/b]: не забывайте вызывать [code]super()[/code] в [method Node._ready]
## и в [method Node._physics_process], если Вы переопределяете их
## (если, конечно, не хотите перезаписать существующую логику).

## Издаётся, когда снаряд куда-то попадает.
signal hit(where: Vector2, what: Entity)
## Издаётся, когда снаряд уничтожается.
signal destroyed(where: Vector2)
## Скорость снаряда.
@export var speed := 1280.0
## Эффект попадания снаряда.
@export var hit_vfx_scene: PackedScene
## Направление движения снаряда. Устанавливается в [method Node._ready] из [member Node2D.rotation].
var direction: Vector2
var _destroyed := false


func _ready() -> void:
	reset_physics_interpolation()
	direction = Vector2.from_angle(rotation)


func _physics_process(delta: float) -> void:
	position += speed * direction * delta


@rpc("unreliable", "call_local", "authority", 5)
func _destroy(where: Vector2) -> void:
	if _destroyed:
		return
	
	_destroyed = true
	destroyed.emit(where)
	for rd: RayDetector in ray_detectors:
		rd.enabled = false
	for sd: ShapeDetector in shape_detectors:
		sd.enabled = false
	
	if hit_vfx_scene:
		var vfx_parent: Node = get_tree().get_first_node_in_group(&"VfxParent")
		if is_instance_valid(vfx_parent):
			var vfx: Node2D = hit_vfx_scene.instantiate()
			vfx.position = where
			vfx.rotation = rotation
			vfx.scale.y = sign(scale.y)
			vfx_parent.add_child(vfx)
	
	await get_tree().physics_frame
	hide()


## Метод для переопределения. Может использоваться для изменения логики при столкновении снаряда
## с чем-либо. По умолчанию снаряд просто уничтожается.
func _process_hit(where: Vector2, _what: Entity) -> void:
	if multiplayer.is_server():
		_destroy.rpc(where)
	else:
		_destroy(where)


func _on_detector_hit(where: Vector2, what: Entity) -> void:
	hit.emit(where, what)
	_process_hit(where, what)


func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		queue_free()
